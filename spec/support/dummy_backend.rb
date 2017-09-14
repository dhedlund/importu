require "importu/backends"

class DummyBackend
  def self.supported_by_definition?(definition)
    false
  end

  def initialize(finder_fields:, **)
    @finder_fields = finder_fields
    @objects = []
    @max_id = 0
  end

  def find(record)
    @finder_fields.detect do |field_group|
      if field_group.respond_to?(:call) # proc
        raise "proc-based finder scopes not supported for dummy backend"
      else
        values = record.values_at(*Array(field_group))
        object = @objects.detect {|o| values == o.values_at(*Array(field_group)) }
        break object if object
      end
    end
  end

  def unique_id(object)
    object[:id]
  end

  def create(record)
    object = { id: @max_id += 1 }.merge(record.to_hash)
    @objects << object
    [:created, object]
  end

  def update(record, object)
    new_object = object.merge(record.to_hash)

    if new_object == object
      [:unchanged, new_object]
    else
      @objects[object[:id]-1] = new_object
      [:updated, new_object]
    end
  end

end

Importu::Backends.registry.register(:dummy, DummyBackend)
