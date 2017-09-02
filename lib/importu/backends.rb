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

  def guess_from_definition!(definition)
    return lookup(definition.model_backend) if definition.model_backend

    matched = @registered.select do |name,backend|
      backend.supported_by_definition?(definition) rescue false
    end

    if matched.one?
      matched.values.first
    elsif matched.none?
      raise Importu::BackendMatchError, "No backends detected from importer " +
        "definition. Try adding `backend :mybackend` to your definition. " +
        "Known values are: " + names.map {|v|":#{v}"}.join(", ")
    else
      raise Importu::BackendMatchError, "Backend auto-detection is " +
        "ambiguous, multiple candidates match. Try adding `backend " +
        ":mybackend` to your definition. Matched backends are: " +
        matched.keys.map {|v|":#{v}"}.join(", ")
    end
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

end
