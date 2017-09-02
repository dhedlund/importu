require "importu/backends"

class DummyBackend
  def self.supported_by_definition?(definition)
    false
  end

  def initialize(definition)
  end

  def find(record)
    nil
  end

  def object_key(object)
    nil
  end

  def create(record, &block)
    :created
  end

  def update(record, &block)
    :updated
  end

end

Importu::Backends.registry.register(:dummy, DummyBackend)
