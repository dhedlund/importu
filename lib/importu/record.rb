require "importu/exceptions"
require "importu/import_context"

class Importu::Record
  attr_reader :data, :raw_data

  include Enumerable

  extend Forwardable
  delegate [:keys, :values, :each, :[], :key?] => :record_hash

  def initialize(data, raw_data, context, fields:, preprocessor: nil, postprocessor: nil, **)
    @data, @raw_data = data, raw_data
    @preprocessor = preprocessor
    @postprocessor = postprocessor
    @field_definitions = fields
    @context = context.new(data)
  end

  def record_hash
    @record_hash ||= generate_record_hash
  end

  def to_hash
    record_hash
  end

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&@preprocessor) if @preprocessor
    instance_exec(object, record_hash, &block) if block

    # filter out any fields we're not allowed to copy for this action
    allowed_fields = @field_definitions.select {|n,d| d[action] }.keys
    concrete_fields = @field_definitions.reject {|n,d| d[:abstract] }.keys
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
    @field_definitions.keys.inject({}) do |hash,name|
      hash[name.to_sym] = @context.field_value(name)
      hash
    end
  end

  private

  attr_reader :object, :action # needed for exposing to instance_eval'd blocks
  alias_method :record, :record_hash # FIXME: used anymore, maybe also for ^?

end
