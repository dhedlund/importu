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

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&@preprocessor) if @preprocessor
    instance_exec(object, self, &block) if block

    # filter out any fields we're not allowed to copy for this action
    allowed_fields = @field_definitions.select {|n,d| d[action] }.keys
    concrete_fields = @field_definitions.reject {|n,d| d[:abstract] }.keys
    field_names = keys & allowed_fields & concrete_fields

    unsupported = field_names.reject {|n| object.respond_to?("#{n}=") }
    if unsupported.any?
      raise "model does not support assigning fields: #{unsupported.to_sentence}"
    end

    (keys & allowed_fields & concrete_fields).each do |name|
      if object.respond_to?("#{name}=")
        object.send("#{name}=", self[name])
      else
      end
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
