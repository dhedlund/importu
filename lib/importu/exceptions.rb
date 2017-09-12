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
    attr_reader :validation_errors

    def initialize(message = nil, validation_errors = nil)
      @validation_errors = validation_errors
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
    attr_reader :definition

    def initialize(definition)
      @definition = definition
    end

    def message
      field = definition[:label] || definition[:name]
      "missing field \"#{field}\" from source data"
    end
  end
end
