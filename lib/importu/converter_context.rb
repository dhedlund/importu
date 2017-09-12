require "importu/exceptions"

# Provides a limited environment in which field conversion can occur. Exists
# primarily to prevent custom converters from gaining access to too much of
# the environment that might otherwise change in the future.
class Importu::ConverterContext

  def initialize(data)
    @data = data
  end

  def self.with_config(converters:, fields:, **)
    Class.new(self) do
      define_method(:field_definitions) { fields }
      converters.each {|name,block| define_method(name, &block) }
    end
  end

  def field_value(name)
    definition = fetch_field_definition(name)

    begin
      value = instance_exec(name, &definition[:converter])
    rescue ArgumentError => e
      # conversion of field value most likely failed
      raise Importu::FieldParseError.new(name, e.message)
    end

    if value.nil? && definition[:required]
      raise Importu::MissingField, definition
    else
      value.nil? ? definition[:default] : value
    end
  end

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
