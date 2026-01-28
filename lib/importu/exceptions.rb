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
  # @api public
  class InvalidDefinition < ImportuException; end

  # Raised when source data cannot be parsed.
  #
  # @api public
  class InvalidInput < ImportuException; end

  # Raised when a requested backend is not registered.
  #
  # @api public
  class BackendNotRegistered < ImportuException; end

  # Raised when no backend matches the configured model.
  #
  # @api public
  class BackendMatchError < ImportuException; end

  # Raised when fields cannot be assigned to the model.
  #
  # @api public
  class UnassignableFields < ImportuException; end

  # Raised when a record fails validation during import.
  #
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
  # @api public
  class DuplicateRecord < InvalidRecord; end

  # Raised when a required field is missing from source data.
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
