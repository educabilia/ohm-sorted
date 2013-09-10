require 'ohm'
require 'ohm/contrib'

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
    end

    def range
      @options.fetch(:range, "-inf".."inf")
    end

    def offset
      @options.fetch(:offset, 0)
    end

    def count
      @options.fetch(:count, -1)
    end

    def between(first, last)
      range = first.to_f..last.to_f
      opts = @options.merge(range: range)
      SortedSet.new(key, namespace, model, opts)
    end

    def slice(*args)
      if args.count == 1
        self[args.first]
      elsif args.count == 2
        offset, count = *args
        opts = @options.merge(offset: offset, count: count)
        SortedSet.new(key, namespace, model, opts)
      else
        raise ArgumentError
      end
    end

    def ids
      execute do |key|
        db.zrangebyscore(key, range.begin, range.end,
          limit: [offset, count])
      end
    end
  end

  if defined?(BasicSet)
    class SortedSet < BasicSet
      include SortedMethods

      def size
        execute { |key| db.zcard(key) }
      end

      def first
        fetch(execute { |key| db.zrange(key, 0, 1) }).first
      end

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

      attr :key
      attr :namespace
      attr :model

      def initialize(key, namespace, model, options={})
        @key = key
        @model = model
        @namespace = namespace
        @options = options
      end

      def db
        model.db
      end

      def each(&block)
        ids.each { |id| block.call(model.to_proc[id]) }
      end

      def [](id)
        model[id] if !!db.zrank(key, id)
      end

      def size
        db.zcard(key)
      end

      def empty?
        size == 0
      end

      def all
        ids.map(&model)
      end

      def first
        id = db.zrange(key, 0, 1).first
        model[id] unless id.empty?
      end

      def include?(model)
        !!db.zrank(key, model.id)
      end

      def inspect
        "#<SortedSet (#{model}): #{db.zrange(key, 0, -1).inspect}>"
      end

    private
      def execute
        yield key
      end
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
        if dict.keys.size == 1
          index_key << dict.keys.first
          index_key << dict.values.first
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
      self.class.sorted_indices.each do |args|
        attribute, options = *args

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
