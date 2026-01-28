# frozen_string_literal: true
module Importu
  # Base class for all Importu exceptions.
  #
  # @api public
  class ImportuException < StandardError
    # Returns the exception class name without module prefix.
    #
    # @return [String] the short class name
    def name
      self.class.name[/[^:]+$/]
    end
  end

  # Raised when an importer definition is invalid.
  #
  # Common causes:
  # - Referencing an undefined field in a converter
  # - Using an unregistered converter type
  #
  # @api public
  class InvalidDefinition < ImportuException; end

  # Raised when source data cannot be parsed.
  #
  # Common causes:
  # - Malformed CSV, JSON, or XML
  # - Empty source file
  # - Encoding issues
  #
  # @api public
  class InvalidInput < ImportuException; end

  # Raised when a requested backend is not registered.
  #
  # @example
  #   model "Book", backend: :nonexistent  # raises BackendNotRegistered
  #
  # @api public
  class BackendNotRegistered < ImportuException; end

  # Raised when no backend matches the configured model.
  #
  # This happens during auto-detection when no registered backend
  # recognizes the model class, or when multiple backends match.
  #
  # @example Fix by specifying backend explicitly
  #   model "Book", backend: :active_record
  #
  # @api public
  class BackendMatchError < ImportuException; end

  # Raised when fields cannot be assigned to the model.
  #
  # This happens when the model doesn't have setter methods for
  # all the fields defined in the importer.
  #
  # @api public
  class UnassignableFields < ImportuException; end

  # Raised when a record fails validation during import.
  #
  # This is the base class for record-level errors. The import continues
  # processing other records; failed records are tracked in the Summary.
  #
  # @see Importu::Summary#validation_errors
  # @see Importu::Summary#itemized_errors
  # @api public
  class InvalidRecord < ImportuException
    # @return [Array<String>, nil] validation error messages
    attr_reader :validation_errors

    # @return [String, nil] aggregation-friendly error message
    attr_reader :normalized_message

    # Creates a new InvalidRecord exception.
    #
    # @param message [String, nil] the error message
    # @param validation_errors [Array<String>, nil] detailed validation errors
    # @param normalized_message [String, nil] message for error aggregation
    def initialize(message = nil, validation_errors = nil, normalized_message: nil)
      @validation_errors = validation_errors
      @normalized_message = normalized_message
      super(message)
    end
  end

  # Raised when a field value cannot be parsed or converted.
  #
  # Common causes:
  # - Invalid date format: "not-a-date" for a date field
  # - Invalid number: "abc" for an integer field
  # - Invalid boolean: "maybe" for a boolean field
  #
  # @api public
  class FieldParseError < InvalidRecord
    # @return [Symbol] the name of the field that failed parsing
    attr_reader :field_name

    # Creates a new FieldParseError.
    #
    # @param field_name [Symbol] the field that failed
    # @param message [String] description of the parse error
    def initialize(field_name, message)
      @field_name = field_name
      @message = message
      super(message)
    end

    # Returns the error message with field name prefix.
    #
    # @return [String] formatted error message
    def to_s
      "#{@field_name}: #{@message}"
    end
  end

  # Raised when a record is a duplicate of one already processed.
  #
  # Duplicates are detected based on the find_by fields. If two records
  # in the same import have matching finder field values, the second
  # is marked as a duplicate.
  #
  # @see Importu::ConfigDSL#find_by
  # @api public
  class DuplicateRecord < InvalidRecord; end

  # Raised when a required field is missing from source data.
  #
  # By default, all fields are required. Use `required: false` to make
  # a field optional.
  #
  # @example Making a field optional
  #   field :notes, required: false
  #
  # @api public
  class MissingField < InvalidRecord
    # @return [Hash] the field definition that was missing
    attr_reader :definition

    # @return [Array<String>, nil] fields that were available in source
    attr_reader :available_fields

    # Creates a new MissingField exception.
    #
    # @param definition [Hash] the field definition
    # @param available_fields [Array<String>, nil] fields present in source data
    def initialize(definition, available_fields: nil)
      @definition = definition
      @available_fields = available_fields
    end

    # Returns a helpful error message listing available fields.
    #
    # @return [String] the error message
    def message
      field = definition[:label] || definition[:name]
      msg = "missing field \"#{field}\" from source data"
      if available_fields&.any?
        msg += "; available fields: #{available_fields.join(", ")}"
      end
      msg
    end
  end
end
