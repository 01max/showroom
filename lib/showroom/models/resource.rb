# frozen_string_literal: true

module Showroom
  # Base class for all Showroom model objects.
  #
  # Wraps a plain Hash, providing dot-notation attribute access, association
  # DSL macros ({.has_many} / {.has_one}), deep serialization via {#to_h},
  # and a configurable {#inspect} output via {.main_attrs}.
  #
  # @example Basic usage
  #   resource = Resource.new('id' => 1, 'title' => 'Foo')
  #   resource.id     # => 1
  #   resource.title  # => "Foo"
  class Resource
    # @return [Hash] the normalized attribute hash
    attr_reader :attrs

    # Initializes a Resource from a Hash, normalizing all keys to strings.
    #
    # @param hash [Hash] attribute data
    def initialize(hash = {})
      @attrs = hash.transform_keys(&:to_s)
    end

    # Declares which attribute keys are included in {#inspect} output.
    #
    # @param keys [Array<Symbol>] attribute names to display in inspect
    # @return [void]
    def self.main_attrs(*keys)
      @main_attrs = keys.map(&:to_s)
    end

    # Returns the list of keys configured via {.main_attrs}.
    #
    # @return [Array<String>]
    def self.main_attr_keys
      @main_attrs || []
    end

    # Defines a reader that wraps the array at +attrs[name]+ as instances
    # of +klass+.
    #
    # @param name [Symbol] attribute name (plural)
    # @param klass [Class] model class to wrap each element in
    # @return [void]
    def self.has_many(name, klass) # rubocop:disable Naming/PredicatePrefix
      define_method(name) do
        @attrs[name.to_s] = Array(@attrs[name.to_s]).map do |item|
          item.is_a?(klass) ? item : klass.new(item)
        end
        @attrs[name.to_s]
      end
    end

    # Defines a reader that wraps the hash at +attrs[name]+ as an instance
    # of +klass+, or returns +nil+ when absent.
    #
    # @param name [Symbol] attribute name (singular)
    # @param klass [Class] model class to wrap the value in
    # @return [void]
    def self.has_one(name, klass) # rubocop:disable Naming/PredicatePrefix
      define_method(name) do
        value = @attrs[name.to_s]
        return nil if value.nil?

        value.is_a?(klass) ? value : klass.new(value)
      end
    end

    # Raw access to an attribute by key.
    #
    # @param key [String, Symbol] attribute name
    # @return [Object, nil]
    def [](key)
      @attrs[key.to_s]
    end

    # Deep-converts the resource (and any nested resources) back to a plain Hash.
    #
    # @return [Hash]
    def to_h
      @attrs.transform_values { |v| deep_unwrap(v) }
    end

    # Returns a developer-friendly string showing {.main_attrs} values.
    #
    # @return [String]
    def inspect
      keys = self.class.main_attr_keys
      pairs = keys.filter_map do |k|
        value = @attrs[k]
        "#{k}: #{value.inspect}" if @attrs.key?(k)
      end
      "#<#{self.class.name} #{pairs.join(', ')}>"
    end

    # Compares two resources by their underlying attribute hashes.
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && other.attrs == @attrs
    end

    # Delegates attribute lookups to @attrs, and caches the method on first call.
    #
    # @param name [Symbol] method name
    # @param args [Array] method arguments (none expected for attr readers)
    # @return [Object, nil]
    def method_missing(name, *args, &)
      key = name.to_s
      if @attrs.key?(key)
        self.class.define_method(name) { @attrs[key] }
        @attrs[key]
      else
        super
      end
    end

    # @param name [Symbol]
    # @param include_private [Boolean]
    # @return [Boolean]
    def respond_to_missing?(name, include_private = false)
      @attrs.key?(name.to_s) || super
    end

    private

    # Recursively converts Resource instances and arrays back to plain values.
    #
    # @param value [Object]
    # @return [Object]
    def deep_unwrap(value)
      case value
      when Resource then value.to_h
      when Array    then value.map { |v| deep_unwrap(v) }
      else               value
      end
    end
  end
end
