module Importu
  class ImportuException < StandardError
    def name
      self.class.name[/[^:]+$/]
    end
  end

  class InvalidInput < ImportuException; end
  class InvalidRecord < ImportuException; end

  class FieldParseError < InvalidRecord; end
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
