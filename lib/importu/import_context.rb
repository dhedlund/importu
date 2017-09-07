require "importu/exceptions"

class Importu::ImportContext

  attr_reader :data, :field_definitions

  def initialize(data, fields:, converters:)
    @data = data
    @field_definitions = fields
    @converters = converters
  end

  def convert(name, converter, **options)
    definition = @field_definitions.fetch(name, {})
    default = options.fetch(:default) { definition[:default] }
    required = options.fetch(:required) { definition[:required] }
    converter = converter.respond_to?(:call) \
      ? converter # Proc
      : @converters.fetch(converter) # Symbol

    begin
      value = instance_exec(name, options, &converter)
      value.nil? ? default : value

    rescue Importu::MissingField => e
      raise if required
      default

    rescue ArgumentError => e
      # conversion of field value most likely failed
      raise Importu::FieldParseError, "#{name}: #{e.message}"
    end
  end

  def field_value(name, **options)
    field_definition = @field_definitions[name] \
      or raise "importer field not defined: #{name}"

    convert(name, field_definition[:converter], options)
  end

  private def method_missing(meth, *args, &block)
    if @converters[meth]
      convert(args[0], meth, args[1]||{}) # convert(name, converter, options)
    else
      super
    end
  end 

end
