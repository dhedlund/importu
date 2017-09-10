require "importu/backends"
require "importu/exceptions"

class Importu::Backends::ActiveRecord

  def self.supported_by_model?(model)
    model < ActiveRecord::Base # Inherits from
  end

  def initialize(model:, finder_fields:, before_save: nil, **)
    @model = model.is_a?(String) ? self.class.const_get(model) : model
    @finder_fields = finder_fields
    @before_save = before_save
  end

  def find(record)
    return unless @finder_fields

    @finder_fields.each do |field_group|
      if field_group.respond_to?(:call) # proc
        object = @model.instance_exec(record, &field_group).first
      else
        conditions = Hash[Array(field_group).map {|f| [f, record[f]]}]
        object = @model.where(conditions).first
      end

      return object if object
    end

    nil
  end

  def object_key(object)
    object.respond_to?(:id) ? object.id : nil
  end

  def create(record)
    object = @model.new
    perform_assignment(record, object, :create)
    save(record, object)
  end

  def update(record, object)
    perform_assignment(record, object, :update)
    save(record, object)
  end

  private def perform_assignment(record, object, action)
    AssignmentContext.new(record, object, action).tap do |context|
      context.assign_values
      context.apply(&@before_save)
    end
  end

  private def save(record, object)
    return :unchanged unless object.changed?
    new_record = object.new_record?

    begin
      object.save!
    rescue ActiveRecord::RecordInvalid
      error_msgs = object.errors.map do |name,message|
        name == "base" ? message : "#{name} #{message}"
      end.join(", ")

      raise Importu::InvalidRecord, error_msgs, object.errors.full_messages
    end

    new_record ? :created : :updated
  end

  class AssignmentContext
    attr_reader :record, :object, :action

    def initialize(record, object, action)
      @record, @object, @action = record, object, action
    end

    def apply(&block)
      instance_eval(&block) if block
    end

    def assign_values
      field_names = record.assignable_fields_for(action)

      begin
        field_names.each do |name|
          object.send("#{name}=", record[name])
        end
      rescue NoMethodError
        raise_unassignable_fields!(field_names)
      end
    end

    private def raise_unassignable_fields!(field_names)
      unassignable = field_names.reject {|n| object.respond_to?("#{n}=") }
      raise "model does not support assigning fields: " + unassignable.join(", ")
    end
  end

end

Importu::Backends.registry.register(:active_record, Importu::Backends::ActiveRecord)
