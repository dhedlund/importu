require "importu/backends/middleware"
require "importu/exceptions"

class Importu::Backends::Middleware::EnforceAllowedActions < SimpleDelegator

  def initialize(backend, allowed_actions:, **)
    super(backend)
    @allowed_actions = allowed_actions
  end

  def create(record)
    if @allowed_actions.include?(:create)
      super
    else
      raise Importu::InvalidRecord, "not allowed to create record"
    end
  end

  def update(record, object)
    if @allowed_actions.include?(:update)
      super
    else
      raise Importu::InvalidRecord, "not allowed to update record"
    end
  end

end
