# frozen_string_literal: true

require "importu/converter_context"
require "importu/exceptions"

# Represents a single record from the import source. Records lazily convert
# field values on access and behave like hashes, supporting standard hash
# methods like [], fetch, keys, values, and each.
#
# @example Accessing field values
#   record[:title]        # => "The Ruby Programming Language"
#   record.fetch(:author) # => "David Flanagan"
#   record.keys           # => [:title, :author, :isbn]
#
# @example Converting to a plain hash
#   record.to_hash # => { title: "...", author: "...", isbn: "..." }
#
# @api public
class Importu::Record

  extend Forwardable

  # The raw data from the source before conversion.
  #
  # @return [Hash] the raw source data
  # @api public
  attr_reader :data

  # Creates a new record from source data.
  #
  # @param data [Hash] the raw source data
  # @param context [Class] the converter context class
  # @param fields [Hash] field definitions
  # @api private
  def initialize(data, context, fields:, **)
    @data = data
    @field_definitions = fields
    @context = context.new(data)

    @errors = []
  end

  # Returns field names that can be assigned for the given action.
  #
  # @param action [Symbol] :create or :update
  # @return [Array<Symbol>] assignable field names
  # @api semipublic
  def assignable_fields_for(action)
    @field_definitions.each_with_object([]) do |(name, definition), acc|
      if definition[action] == true && definition[:abstract] == false
        acc << name
      end
    end
  end

  # Returns any conversion errors encountered when processing fields.
  #
  # @return [Array<Importu::FieldParseError>] conversion errors
  # @api public
  def errors
    ensure_record_hash
    @errors
  end

  # Converts the record to a hash of field names to converted values.
  #
  # @return [Hash{Symbol => Object}] the converted field values
  # @raise [Importu::InvalidRecord] if any field conversion errors occurred
  # @api public
  def to_hash
    ensure_record_hash

    if errors.any?
      raise Importu::InvalidRecord.new("field parse errors", errors)
    else
      @record_hash
    end
  end

  # Returns whether the record has any conversion errors.
  #
  # @return [Boolean] true if no errors, false otherwise
  # @api public
  def valid?
    ensure_record_hash
    errors.none?
  end

  # @!method [](key)
  #   Access a field value by name.
  #   @param key [Symbol] the field name
  #   @return [Object] the converted value
  #
  # @!method fetch(key, default = nil)
  #   Access a field value with a default.
  #   @param key [Symbol] the field name
  #   @param default [Object] value to return if key not found
  #   @return [Object] the converted value or default
  #
  # @!method keys
  #   Returns all field names.
  #   @return [Array<Symbol>] the field names
  #
  # @!method values
  #   Returns all converted field values.
  #   @return [Array<Object>] the field values
  delegate (Hash.public_instance_methods - public_instance_methods) => :to_hash

  private def ensure_record_hash
    @record_hash ||= @field_definitions.each_with_object({}) do |(name, _), hash|
      begin
        hash[name] = @context.field_value(name)
      rescue Importu::FieldParseError => e
        @errors << e
      end
    end
  end

  # Iterates over source rows, yielding Record instances.
  #
  # @api semipublic
  class Iterator < Enumerator
    # Creates a new iterator over source rows.
    #
    # @param rows [Enumerator] the source rows to iterate
    # @param converters [Hash] converter definitions
    # @param fields [Hash] field definitions
    # @api private
    def initialize(rows, converters:, fields:, **)
      context = Importu::ConverterContext.with_config(
        converters: converters,
        fields: fields,
      )

      super() do |yielder|
        rows.each do |row|
          yielder.yield Importu::Record.new(row, context, fields: fields)
        end
      end
    end
  end

end
