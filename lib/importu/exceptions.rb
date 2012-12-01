module Importu
  class ImportuException < StandardError
    def name
      self.class.name[/[^:]+$/]
    end
  end

  class InvalidInput < ImportuException; end
  class InvalidRecord < ImportuException; end

  class FieldParseError < InvalidRecord; end
  class MissingField < InvalidRecord; end
  class DuplicateRecord < InvalidRecord; end

end
