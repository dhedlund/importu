# frozen_string_literal: true
require "importu/backends/middleware/enforce_allowed_actions"
require "importu/backends/middleware/duplicate_manager_proxy"
require "importu/exceptions"

# Registry for persistence backends.
#
# Backends handle persisting imported records to a data store. The registry
# allows registering custom backends and auto-detecting which backend to use
# based on the model class.
#
# @example Registering a custom backend
#   Importu::Backends.registry.register(:sequel, MySequelBackend)
#
# @example Looking up a backend
#   backend_class = Importu::Backends.registry.lookup(:active_record)
#
# @api semipublic
class Importu::Backends
  # Returns the middleware classes applied to all backends.
  #
  # @return [Array<Class>] middleware classes in application order
  def self.middleware
    [
      Importu::Backends::Middleware::EnforceAllowedActions,
      Importu::Backends::Middleware::DuplicateManagerProxy,
    ]
  end

  # Returns the global backend registry instance.
  #
  # @return [Importu::Backends] the singleton registry
  def self.registry
    @registry ||= new
  end

  # Creates a new backend registry.
  #
  # @api private
  def initialize
    @registered = Hash.new do |_hash, key|
      raise Importu::BackendNotRegistered, key
    end
  end

  # Resolves a backend class from importer configuration.
  #
  # @param name [Symbol, nil] explicit backend name, :auto, or nil for auto-detect
  # @param model [Class, String] the model class or class name
  # @return [Class] the backend class
  # @raise [Importu::BackendNotRegistered] if named backend not found
  # @raise [Importu::BackendMatchError] if auto-detection fails
  def from_config!(name:, model:, **)
    model = model.is_a?(String) ? self.class.const_get(model) : model
    # Support :auto as an explicit way to request auto-detection (same as nil)
    name && name != :auto ? lookup(name) : detect_from_model(model)
  end

  # Looks up a backend by name.
  #
  # @param name [Symbol, String] the backend name
  # @return [Class] the backend class
  # @raise [Importu::BackendNotRegistered] if not found
  def lookup(name)
    @registered[name.to_sym]
  end

  # Returns all registered backend names.
  #
  # @return [Array<Symbol>] registered backend names
  def names
    @registered.keys
  end

  # Registers a backend class.
  #
  # @param name [Symbol, String] the backend name
  # @param klass [Class] the backend class
  # @return [Class] the registered class
  def register(name, klass)
    @registered[name.to_sym] = klass
  end

  private def detect_from_model(model)
    matched = @registered.select do |_name, backend|
      backend.supported_by_model?(model) rescue false
    end

    if matched.one?
      matched.values.first
    elsif matched.none?
      raise Importu::BackendMatchError, "No backends detected from importer " +
        "model. Try adding `backend: :mybackend` to your model definition. " +
        "Known values are: " + names.map {|v| ":#{v}"}.join(", ")
    else
      raise Importu::BackendMatchError, "Backend auto-detection is " +
        "ambiguous, multiple candidates match. Try adding `backend: " +
        ":mybackend` to your model definition. Matched backends are: " +
        matched.keys.map {|v| ":#{v}"}.join(", ")
    end
  end

end
