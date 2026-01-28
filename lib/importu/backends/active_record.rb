# frozen_string_literal: true
require "importu/backends"
require "importu/exceptions"

# Backend for persisting records to ActiveRecord models.
#
# This backend is automatically registered and detected when your model
# inherits from ActiveRecord::Base.
#
# @example Basic usage in an importer
#   class BookImporter < Importu::Importer
#     model "Book"
#     allow_actions :create, :update
#     find_by :isbn
#   end
#
# @api semipublic
class Importu::Backends::ActiveRecord
  # Checks if this backend supports the given model.
  #
  # @param model [Class] the model class
  # @return [Boolean] true if model inherits from ActiveRecord::Base
  def self.supported_by_model?(model)
    model < ActiveRecord::Base # Inherits from
  end

  # Creates a new ActiveRecord backend.
  #
  # @param model [Class, String] the ActiveRecord model class or name
  # @param finder_fields [Array] field groups for finding existing records
  # @param before_save [Proc, nil] optional callback before saving
  # @api private
  def initialize(model:, finder_fields:, before_save: nil, **)
    @model = model.is_a?(String) ? self.class.const_get(model) : model
    @finder_fields = finder_fields
    @before_save = before_save
  end

  # Finds an existing record matching the import data.
  #
  # @param record [Importu::Record] the import record
  # @return [ActiveRecord::Base, nil] the matching record or nil
  def find(record)
    @finder_fields.each do |field_group|
      if field_group.respond_to?(:call) # proc
        object = @model.instance_exec(record, &field_group)
      else
        conditions = field_group.to_h {|f| [f, record[f]]}
        object = @model.where(conditions).first
      end

      return object if object
    end

    nil
  end

  # The unique id representing the object in the database, if one exists.
  def unique_id(object)
    object.respond_to?(:id) ? object.id : nil
  end

  # Creates a new record in the database.
  #
  # @param record [Importu::Record] the import record
  # @return [Array<(Symbol, ActiveRecord::Base)>] status and object
  # @raise [Importu::InvalidRecord] if validation fails
  def create(record)
    object = @model.new
    perform_assignment(record, object, :create)
    save(record, object)
  end

  # Updates an existing record in the database.
  #
  # @param record [Importu::Record] the import record
  # @param object [ActiveRecord::Base] the existing record
  # @return [Array<(Symbol, ActiveRecord::Base)>] status and object
  # @raise [Importu::InvalidRecord] if validation fails
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

  private def save(_record, object)
    return [:unchanged, object] unless object.changed?
    new_record = object.new_record?

    begin
      object.save!
    rescue ActiveRecord::RecordInvalid
      error_msgs = object.errors.map do |error|
        error.attribute == :base ? error.message : "#{error.attribute} #{error.message}"
      end

      # Normalize messages by stripping trailing parenthesized data (e.g., "(value: foo)")
      # This allows similar errors to be aggregated in the Summary.
      normalized_msgs = error_msgs.map { |msg| msg.gsub(/ *\([^)]+\) *$/, "") }

      raise Importu::InvalidRecord.new(
        error_msgs.join(", "),
        object.errors.full_messages,
        normalized_message: normalized_msgs.join(", ")
      )
    end

    [(new_record ? :created : :updated), object]
  end

  # Context for assigning field values to a model instance.
  #
  # This is the execution context for before_save hooks, providing access
  # to the record data, model object, and current action.
  #
  # @api semipublic
  class AssignmentContext
    # @return [Importu::Record] the import record
    attr_reader :record

    # @return [ActiveRecord::Base] the model instance
    attr_reader :object

    # @return [Symbol] the action (:create or :update)
    attr_reader :action

    # @api private
    def initialize(record, object, action)
      @record, @object, @action = record, object, action
    end

    # Executes a block in this context.
    #
    # @yield block to execute with access to record, object, and action
    # @api private
    def apply(&block)
      instance_eval(&block) if block
    end

    # Assigns field values from the record to the object.
    #
    # @raise [Importu::UnassignableFields] if fields cannot be assigned
    # @api private
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
      raise Importu::UnassignableFields, "model does not support assigning " +
        "all fields: " + unassignable.join(", ")
    end
  end

end

Importu::Backends.registry.register(:active_record, Importu::Backends::ActiveRecord)
