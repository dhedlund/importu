# frozen_string_literal: true
module Importu
  class ImportuException < StandardError
    def name
      self.class.name[/[^:]+$/]
    end
  end

  class InvalidDefinition < ImportuException; end
  class InvalidInput < ImportuException; end
  class BackendNotRegistered < ImportuException; end
  class BackendMatchError < ImportuException; end
  class UnassignableFields < ImportuException; end

  class InvalidRecord < ImportuException
    attr_reader :validation_errors, :normalized_message

    def initialize(message = nil, validation_errors = nil, normalized_message: nil)
      @validation_errors = validation_errors
      @normalized_message = normalized_message
      super(message)
    end
  end

  class FieldParseError < InvalidRecord
    attr_reader :field_name

    def initialize(field_name, message)
      @field_name = field_name
      @message = message
      super(message)
    end

    def to_s
      "#{@field_name}: #{@message}"
    end
  end

  class DuplicateRecord < InvalidRecord; end

  class MissingField < InvalidRecord
    attr_reader :definition, :available_fields

    def initialize(definition, available_fields: nil)
      @definition = definition
      @available_fields = available_fields
    end

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
