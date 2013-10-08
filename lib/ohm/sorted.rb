require 'ohm'

begin
  require 'ohm/callbacks'
rescue LoadError
  require 'ohm/contrib/callbacks'
end

module Ohm

  module SortedMethods
    attr :key
    attr :namespace
    attr :model

    def initialize(key, namespace, model, options={})
      @key = key
      @namespace = namespace
      @model = model
      @options = options
      @range = options.fetch(:range, ["-inf", "inf"])
    end

    def offset
      @options.fetch(:offset, 0)
    end

    def count
      @options.fetch(:count, -1)
    end

    def size
      execute { |key| db.zcard(key) }
    end

    def between(first, last)
      range = [first.to_f, last.to_f]
      range.reverse! if reversed?

      opts = @options.merge(range: range)
      RangedSortedSet.new(key, namespace, model, opts)
    end

    def reversed?
      @options.fetch(:reverse, false)
    end

    def reverse
      opts = @options.merge(reverse: !reversed?, range: @range.reverse)

      self.class.new(key, namespace, model, opts)
    end

    def slice(*args)
      if args.count == 1
        self[args.first]
      elsif args.count == 2
        offset, count = *args
        opts = @options.merge(offset: offset, count: count)
        self.class.new(key, namespace, model, opts)
      else
        raise ArgumentError
      end
    end

    def first
      slice(0, 1).to_a.first
    end

    def ids
      if reversed?
        execute { |key| db.zrevrangebyscore(key, @range.first, @range.last, limit: [offset, count]) }
      else
        execute { |key| db.zrangebyscore(key, @range.first, @range.last, limit: [offset, count]) }
      end
    end

    def inspect
      "#<SortedSet (#{model}): #{ids}>"
    end
  end

  if defined?(BasicSet)
    class SortedSet < BasicSet
      include SortedMethods

    private
      def exists?(id)
        execute { |key| !!db.zscore(key, id) }
      end

      def execute
        yield key
      end

      def db
        model.db
      end
    end
  else
    class SortedSet < Model::Collection
      include Ohm::SortedMethods

      def db
        model.db
      end

      def each(&block)
        return to_enum(:each) unless block
        ids.each { |id| block.call(model.to_proc[id]) }
      end

      def [](id)
        model[id] if !!db.zrank(key, id)
      end

      def empty?
        size == 0
      end

      def all
        ids.map(&model)
      end

      def include?(model)
        !!db.zrank(key, model.id)
      end

    private
      def execute
        yield key
      end
    end
  end

  class RangedSortedSet < SortedSet
    def size
      execute { |key| db.zcount(key, @range.first, @range.last) }
    end
  end

  module Sorted
    def self.included(model)
      model.extend(ClassMethods)
    end

    module ClassMethods
      def sorted(attribute, options={})
        sorted_indices << [attribute, options]
      end

      def sorted_indices
        @sorted_indices ||= []
      end

      def sorted_find(attribute, dict={})
        unless sorted_index_exists?(attribute, to_options(dict))
          raise index_not_found(attribute)
        end

        index_key = sorted_index_key(attribute, dict)
        Ohm::SortedSet.new(index_key, key, self)
      end

      def sorted_index_exists?(attribute, options=nil)
        !!sorted_indices.detect { |i| i == [attribute, options] }
      end

      def sorted_index_key(attribute, dict={})
        index_key = [key, "sorted", attribute]
        if dict.size == 1
          index_key.concat(dict.first)
        elsif dict.keys.size > 1
          raise ArgumentError
        end
        index_key.join(":")
      end

    protected
      def index_not_found(attribute)
        if defined?(IndexNotFound)
          IndexNotFound
        else
          Model::IndexNotFound.new(attribute)
        end
      end

      def to_options(dict)
        return {} if dict.empty?
        {group_by: dict.keys.first}
      end
    end

  protected
    def after_create
      add_sorted_indices
      super
    end

    def before_update
      prune_sorted_indices
      super
    end

    def after_update
      add_sorted_indices unless new?
      super
    end

    def before_delete
      remove_sorted_indices
      super
    end

    def add_sorted_indices
      update_sorted_indices do |key, attribute, options|
        score = send(attribute).to_f
        db.zadd(key, score, id)
      end
    end

    def remove_sorted_indices
      update_sorted_indices do |key, attribute, options|
        db.zrem(key, id)
      end
    end

    def prune_sorted_indices
      return if new?
      update_sorted_indices do |key, attribute, options|
        return unless options.include?(:group_by)

        old_value = db.hget(self.key, options[:group_by])
        new_value = send(options[:group_by])

        if old_value != new_value
          opts = {options[:group_by] => old_value}
          key = self.class.sorted_index_key(attribute, opts)
          db.zrem(key, id)
        end
      end
    end

    def update_sorted_indices
      self.class.sorted_indices.each do |attribute, options|
        opts = {}
        if options.include?(:group_by)
          group_by = options[:group_by]
          opts[group_by] = send(group_by)
        end
        key = self.class.sorted_index_key(attribute, opts)

        yield(key, attribute, options)
      end
    end
  end
end
