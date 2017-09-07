require "importu/exceptions"

class Importu::Record
  attr_reader :definition, :data, :raw_data
  attr_reader :field_definitions, :converters

  include Enumerable

  extend Forwardable
  delegate [:keys, :values, :each, :[], :key?] => :record_hash

  def initialize(data, raw_data, fields:, converters:, preprocessor: nil, postprocessor: nil, **)
    @data, @raw_data = data, raw_data
    @preprocessor = preprocessor
    @postprocessor = postprocessor
    @field_definitions = fields
    @converters = converters
  end

  def record_hash
    @record_hash ||= generate_record_hash
  end

  def to_hash
    record_hash
  end

  def convert(name, converter, **options)
    definition = field_definitions.fetch(name, {})
    default = options.fetch(:default) { definition[:default] }
    required = options.fetch(:required) { definition[:required] }
    converter = converter.respond_to?(:call) \
      ? converter # Proc
      : converters.fetch(converter) # Symbol

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
    field_definition = field_definitions[name] \
      or raise "importer field not defined: #{name}"

    convert(name, field_definition[:converter], field_definition.merge(options))
  end

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&@preprocessor) if @preprocessor
    instance_exec(object, record_hash, &block) if block

    # filter out any fields we're not allowed to copy for this action
    allowed_fields = field_definitions.select {|n,d| d[action] }.keys
    concrete_fields = field_definitions.reject {|n,d| d[:abstract] }.keys
    field_names = record_hash.keys & allowed_fields & concrete_fields

    unsupported = field_names.reject {|n| object.respond_to?("#{n}=") }
    if unsupported.any?
      raise "model does not support assigning fields: #{unsupported.to_sentence}"
    end

    (record_hash.keys & allowed_fields & concrete_fields).each do |name|
      if object.respond_to?("#{name}=")
        object.send("#{name}=", record_hash[name])
      else
      end
    end

    instance_eval(&@postprocessor) if @postprocessor

    object
  end

  private def generate_record_hash
    field_definitions.keys.inject({}) do |hash,name|
      hash[name.to_sym] = field_value(name)
      hash
    end
  end

  private def method_missing(meth, *args, &block)
    if converters[meth]
      convert(args[0], meth, args[1]||{}) # convert(name, type, options)
    else
      super
    end
  end

  private

  attr_reader :object, :action # needed for exposing to instance_eval'd blocks
  alias_method :record, :record_hash # FIXME: used anymore, maybe also for ^?

end
