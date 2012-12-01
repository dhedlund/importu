require 'active_support/core_ext/module/delegation'

class Importu::Record
  attr_reader :importer, :data, :raw_data, :definitions

  include Enumerable

  delegate :keys, :values, :each, :[], :key?, :to => :record_hash
  delegate :preprocessor, :postprocessor, :to => :importer
  delegate :definitions, :converters, :to => :importer

  def initialize(importer, data, raw_data)
    @importer, @data, @raw_data = importer, data, raw_data
    @definitions = importer.definitions
  end

  def record_hash
    @record_hash ||= generate_record_hash
  end

  def to_hash
    record_hash
  end

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&preprocessor) if preprocessor
    instance_exec(object, record_hash, &block) if block

    # filter out any fields we're not allowed to copy for this action
    allowed_fields = definitions.select {|n,d| d[action] }.keys
    concrete_fields = definitions.reject {|n,d| d[:abstract] }.keys
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

    instance_eval(&postprocessor) if postprocessor

    object
  end


  private

  attr_reader :object, :action # needed for exposing to instance_eval'd blocks

  alias_method :record, :record_hash

  def generate_record_hash
    record_hash = definitions.inject({}) do |hash,(name,definition)|
      begin
        converter = definition[:converter] || importer.converters[:clean]
        hash[name.to_sym] = case converter.arity
          when 2 then converter.call(data, definition)
          when 1 then instance_exec(name, &converter)
          when 0 then instance_exec(&converter)
        end
        hash

      rescue Importu::MissingField => e
        raise e if definition[:required]
        hash

      rescue ArgumentError => e
        # conversion of field value most likely failed
        raise Importu::FieldParseError, "#{name}: #{e.message}"
      end
    end

    record_hash
  end

  def method_missing(meth, *args, &block)
    if converter = importer.converters[meth]
      case args.count
        when 2 then converter.call(*args)
        when 1 then instance_exec(data, definitions[args[0]], &converter)
      end
    else
      super
    end
  end

end
