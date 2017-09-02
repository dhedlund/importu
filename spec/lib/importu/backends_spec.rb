require "spec_helper"

RSpec.describe Importu::Backends do
  subject(:registry) { described_class.new }

  describe ".registry" do
    it "returns a registry singleton" do
      expect(described_class.registry).to be described_class.registry
    end

    it "returns a registry-like object" do
      expect(described_class.registry).to respond_to("register")
      expect(described_class.registry).to respond_to("lookup")
    end
  end

  describe "#lookup" do
    let(:marvelous_impl) { Class.new }
    before { registry.register(:marvelous, marvelous_impl) }

    it "raises a BackendNotRegistered exception if backend not found" do
      expect { registry.lookup(:foo) }
        .to raise_error(Importu::BackendNotRegistered)
    end

    it "supports lookups by symbol-based name" do
      expect(registry.lookup(:marvelous)).to eq marvelous_impl
    end
    it "supports lookups by string-based name" do
      expect(registry.lookup("marvelous")).to eq marvelous_impl
    end
  end

  describe "#names" do
    it "returns the names of all registered backends" do
      registry.register(:backend1, Class.new)
      registry.register(:backend2, Class.new)
      registry.register(:backend3, Class.new)
      expect(registry.names).to include(:backend1, :backend2, :backend3)
    end
  end

  describe "#register" do
    let(:backend1) { Class.new }
    let(:backend2) { Class.new }

    it "allows registering multiple backends" do
      registry.register(:backend1, backend1)
      registry.register(:backend2, backend2)
      expect(registry.lookup(:backend1)).to eq backend1
      expect(registry.lookup(:backend2)).to eq backend2
    end
  end

end
