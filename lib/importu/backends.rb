class Importu::Backends
  def self.registry
    @registry ||= self.new
  end

  def initialize
    @registered = Hash.new do |hash,key|
      raise Importu::BackendNotRegistered, key
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
