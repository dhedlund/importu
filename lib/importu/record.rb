class Importu::Record

  extend Forwardable

  attr_reader :data

  def initialize(data, context, fields:, preprocessor: nil, postprocessor: nil, **)
    @data = data
    @preprocessor = preprocessor
    @postprocessor = postprocessor
    @field_definitions = fields
    @context = context.new(data)
  end

  def assignable_fields_for(action)
    @field_definitions.each_with_object([]) do |(name,definition),acc|
      if definition[action] == true && definition[:abstract] == false
        acc << name
      end
    end
  end

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&@preprocessor) if @preprocessor
    instance_exec(object, self, &block) if block

    field_names = assignable_fields_for(action)

    unsupported = field_names.reject {|n| object.respond_to?("#{n}=") }
    if unsupported.any?
      raise "model does not support assigning fields: #{unsupported.to_sentence}"
    end

    field_names.each do |name|
      object.send("#{name}=", self[name])
    end

    instance_eval(&@postprocessor) if @postprocessor

    object
  end

  def to_hash
    @record_hash ||= @field_definitions.each_with_object({}) do |(name,_),hash|
      hash[name] = @context.field_value(name)
    end
  end

  # A record should behave as similarly to a hash as possible, so forward all
  # hash methods not defined on this class to our hash of converted values.
  delegate (Hash.public_instance_methods - public_instance_methods) => :to_hash


  private

  attr_reader :object, :action # needed for exposing to instance_eval'd blocks
  alias_method :record, :to_hash # FIXME: used anymore, maybe also for ^?

end
