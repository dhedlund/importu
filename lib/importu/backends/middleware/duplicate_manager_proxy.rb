require "importu/backends/middleware"
require "importu/duplicate_manager"

# Wraps any model-based backend adapter to provide duplicate detection.
class Importu::Backends::Middleware::DuplicateManagerProxy < SimpleDelegator

  def initialize(backend, finder_fields:, **)
    super(backend)
    @manager = Importu::DuplicateManager.new(finder_fields: finder_fields)
  end

  # Before passing to the backend for create, make sure the record is not
  # a duplicate by using the finder field information that is available.
  # When creating a new object, we will need to record that object as
  # encountered as soon as it has been given a unique id. Any updates
  # to that record within the same import will be treated as duplicate.
  def create(record)
    @manager.check_record!(record)

    result, object = super

    # Record the newly created object as encountered
    @manager.check_object!(unique_id(object))

    [result, object]
  end

  # Before passing to the backend for update, make sure the record is not
  # a duplicate by using the finder field information that is available.
  # Also check the object's unique identifier to ensure we have not already
  # tried to change the object from a previous record import.
  def update(record, object)
    @manager.check_record!(record)
    @manager.check_object!(unique_id(object))
    super
  end

end
