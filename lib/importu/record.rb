class Importu::Record

  extend Forwardable

  attr_reader :data

  def initialize(data, context, fields:, **)
    @data = data
    @field_definitions = fields
    @context = context.new(data)

    @errors = []
  end

  def assignable_fields_for(action)
    @field_definitions.each_with_object([]) do |(name,definition),acc|
      if definition[action] == true && definition[:abstract] == false
        acc << name
      end
    end
  end

  def errors
    ensure_record_hash
    @errors
  end

  def to_hash
    ensure_record_hash

    if errors.any?
      raise Importu::InvalidRecord.new("field parse errors", errors)
    else
      @record_hash
    end
  end

  def valid?
    ensure_record_hash
    errors.none?
  end

  # A record should behave as similarly to a hash as possible, so forward all
  # hash methods not defined on this class to our hash of converted values.
  delegate (Hash.public_instance_methods - public_instance_methods) => :to_hash

  private def ensure_record_hash
    @record_hash ||= @field_definitions.each_with_object({}) do |(name,_),hash|
      begin
        hash[name] = @context.field_value(name)
      rescue Importu::FieldParseError => e
        @errors << e
      end
    end
  end

end
