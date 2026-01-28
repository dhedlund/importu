# frozen_string_literal: true
require "importu/exceptions"

# Execution context for field converters.
#
# When you define a custom converter or field block, the code executes within
# a ConverterContext instance. This provides access to field values and other
# converters while isolating converter code from internal implementation details.
#
# @example Accessing values in a custom converter
#   converter :full_name do |field_name|
#     # raw_value gets the untransformed source data
#     first = raw_value(:first_name)
#     last = raw_value(:last_name)
#     "#{first} #{last}".strip
#   end
#
# @example Referencing other fields
#   field :tax do
#     # field_value gets the converted value of another field
#     subtotal = field_value(:subtotal)
#     subtotal * 0.08
#   end
#
# @api semipublic
class Importu::ConverterContext
  # Creates a new context with the given source data.
  #
  # @param data [Hash] the raw source data for one record
  # @api private
  def initialize(data)
    @data = data
  end

  # Creates a context subclass configured with converters and field definitions.
  #
  # @param converters [Hash{Symbol => Proc}] converter name to implementation
  # @param fields [Hash{Symbol => Hash}] field name to definition
  # @return [Class] a configured ConverterContext subclass
  # @api private
  def self.with_config(converters:, fields:, **)
    Class.new(self) do
      define_method(:field_definitions) { fields }
      converters.each {|name, block| define_method(name, &block) }
    end
  end

  # Returns the converted value of a field.
  #
  # Runs the field's converter and applies validation. Use this when you need
  # the final, converted value of another field.
  #
  # @param name [Symbol] the field name
  # @return [Object] the converted field value
  # @raise [Importu::FieldParseError] if conversion fails
  # @raise [Importu::MissingField] if field is required but missing
  # @raise [Importu::InvalidDefinition] if field is not defined
  def field_value(name)
    definition = fetch_field_definition(name)

    begin
      value = instance_exec(name, &definition[:converter])
    rescue ArgumentError => e
      # conversion of field value most likely failed
      raise Importu::FieldParseError.new(name, e.message)
    end

    if value.nil? && definition[:required]
      raise Importu::MissingField.new(definition, available_fields: @data.keys)
    else
      value.nil? ? definition[:default] : value
    end
  end

  # Returns the raw, unconverted value from source data.
  #
  # Use this when you need the original value before any conversion. The value
  # is looked up using the field's label (which defaults to the field name).
  #
  # @param name [Symbol] the field name
  # @return [Object, nil] the raw source value
  # @raise [Importu::InvalidDefinition] if field is not defined
  def raw_value(name)
    definition = fetch_field_definition(name)
    @data[definition.fetch(:label)]
  end

  private def fetch_field_definition(name)
    field_definitions.fetch(name) do
      raise Importu::InvalidDefinition, "importer field not defined: #{name}"
    end
  end

end
