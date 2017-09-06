require "importu/backends"
require "importu/exceptions"

class Importu::Backends::ActiveRecord

  def self.supported_by_model?(model)
    model < ActiveRecord::Base # Inherits from
  end

  def initialize(model:, finder_fields:, **)
    @model = model.is_a?(String) ? self.class.const_get(model) : model
    @finder_fields = finder_fields
  end

  def find(record)
    return unless @finder_fields

    @finder_fields.each do |field_group|
      if field_group.respond_to?(:call) # proc
        object = @model.instance_exec(record, &field_group).first
      else
        conditions = Hash[field_group.map {|f| [f, record[f]]}]
        object = @model.where(conditions).first
      end

      return object if object
    end

    nil
  end

  def object_key(object)
    object.respond_to?(:id) ? object.id : nil
  end

  def create(record, &block)
    object = @model.new
    record.assign_to(object, :create, &block)
    save(record, object)
    :created
  end

  def update(record, object, &block)
    record.assign_to(object, :update, &block)
    save(record, object)
    :updated
  end

  private def save(record, object)
    return :unchanged unless object.changed?

    begin
      object.save!

    rescue ActiveRecord::RecordInvalid
      error_msgs = object.errors.map do |name,message|
        name = (record.field_definitions[name]||{})[:label]
        name == "base" ? message : "#{name} #{message}"
      end.join(", ")

      raise Importu::InvalidRecord, error_msgs, object.errors.full_messages
    end

  end

end

Importu::Backends.registry.register(:active_record, Importu::Backends::ActiveRecord)
