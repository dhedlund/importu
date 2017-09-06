require "importu/exceptions"

class Importu::Backends
  def self.registry
    @registry ||= self.new
  end

  def initialize
    @registered = Hash.new do |hash,key|
      raise Importu::BackendNotRegistered, key
    end
  end

  def from_config!(name:, model:, **)
    model = model.is_a?(String) ? self.class.const_get(model) : model
    name ? lookup(name) : detect_from_model(model)
  end

  def lookup(name)
    @registered[name.to_sym]
  end

  def names
    @registered.keys
  end

  def register(name, klass)
    @registered[name.to_sym] = klass
  end

  private def detect_from_model(model)
    matched = @registered.select do |name,backend|
      backend.supported_by_model?(model) rescue false
    end

    if matched.one?
      matched.values.first
    elsif matched.none?
      raise Importu::BackendMatchError, "No backends detected from importer " +
        "model. Try adding `backend: :mybackend` to your model definition. " +
        "Known values are: " + names.map {|v|":#{v}"}.join(", ")
    else
      raise Importu::BackendMatchError, "Backend auto-detection is " +
        "ambiguous, multiple candidates match. Try adding `backend: " +
        ":mybackend` to your model definition. Matched backends are: " +
        matched.keys.map {|v|":#{v}"}.join(", ")
    end
  end

end
