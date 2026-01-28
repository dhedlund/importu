# frozen_string_literal: true
require "delegate"

require "importu/backends/middleware"
require "importu/exceptions"

# Middleware that enforces allowed actions on a backend.
#
# Wraps a backend and raises InvalidRecord if a create or update action
# is attempted that isn't in the allowed_actions list.
#
# @api private
class Importu::Backends::Middleware::EnforceAllowedActions < SimpleDelegator
  # Creates middleware wrapping the given backend.
  #
  # @param backend [Object] the backend to wrap
  # @param allowed_actions [Array<Symbol>] actions that are permitted
  def initialize(backend, allowed_actions:, **)
    super(backend)
    @allowed_actions = allowed_actions
  end

  # Creates a record, if create action is allowed.
  #
  # @param record [Importu::Record] the import record
  # @return [Array] status and object from wrapped backend
  # @raise [Importu::InvalidRecord] if create not allowed
  def create(record)
    if @allowed_actions.include?(:create)
      super
    else
      raise Importu::InvalidRecord,
            "create action not allowed; add `allow_actions :create` to your importer"
    end
  end

  # Updates a record, if update action is allowed.
  #
  # @param record [Importu::Record] the import record
  # @param object [Object] the existing record
  # @return [Array] status and object from wrapped backend
  # @raise [Importu::InvalidRecord] if update not allowed
  def update(record, object)
    if @allowed_actions.include?(:update)
      super
    else
      raise Importu::InvalidRecord,
            "update action not allowed; add `allow_actions :create, :update` to your importer"
    end
  end

end
