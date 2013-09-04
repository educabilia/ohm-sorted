require 'ohm'
require 'ohm/contrib'

module Ohm
  class SortedSet < BasicSet
    attr :key
    attr :namespace
    attr :model

    def initialize(key, namespace, model) 
      @key = key
      @namespace = namespace
      @model = model
    end

    def ids
      execute { |key| db.zrange(key, 0, -1) }
    end

    def size
      execute { |key| db.zcard(key) }
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

  module Sorted
    def self.included(model)
      model.extend(ClassMethods)
    end

    module ClassMethods
      def sorted(attr, options={})
        sorted_indices[attr] = options
      end

      def sorted_indices
        @sorted_indices ||= {}
      end

      def sorted_find(attribute, dict)
        raise IndexNotFound unless sorted_index_exists?(dict.keys.first, by: attribute)

        index_key = sorted_index_key(attribute, dict)
        Ohm::SortedSet.new(index_key, key, self)
      end

      def sorted_index_exists?(attribute, options=nil)
        index = sorted_indices[attribute]
        !!(index && (options.nil? || options == index))
      end

      def sorted_index_key(attribute, dict)
        [key, "sorted", dict.keys.first, attribute, dict.values.first].join(":")
      end
    end

  protected
    def after_create
      add_sorted_indices
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
        score = send(options[:by]).to_f
        db.zadd(key, score, id)
      end
    end

    def remove_sorted_indices
      update_sorted_indices do |key, attribute, options|
        db.zrem(key, id)
      end
    end

    def update_sorted_indices
      self.class.sorted_indices.each do |args|
        attribute, options = *args
        key = self.class.sorted_index_key(
          options[:by], {attribute => send(attribute)})
        yield(key, attribute, options)
      end
    end
  end
end
