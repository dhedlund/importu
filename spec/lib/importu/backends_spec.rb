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

  describe "#guess_from_definition!" do
    context "when a model backend is specified" do
      let(:definition) do
        Class.new(Importu::Importer) do
          model "MyModelGuest", backend: :cherry_scones
        end
      end

      context "and the backend is registered" do
        let!(:backend) { registry.register(:cherry_scones, Class.new) }

        it "returns the backend" do
          expect(registry.guess_from_definition!(definition)).to eq backend
        end
      end

      context "and the backend is not registered" do
        it "raises a BackendNotRegistered error" do
          expect { registry.guess_from_definition!(definition) }
            .to raise_error(Importu::BackendNotRegistered)
        end
      end
    end

    context "when a model backend is not specified" do
      let(:supported) { Class.new { def self.supported_by_definition?(*); true; end } }
      let(:unsupported) { Class.new { def self.supported_by_definition?(*); false; end } }

      let(:definition) do
        Class.new(Importu::Importer) do
          model "MyModelGuest"
        end
      end

      context "and no backends support the model" do
        it "raises a BackendMatch error" do
          expect { registry.guess_from_definition!(definition) }
            .to raise_error(Importu::BackendMatchError)
        end
      end

      context "and exactly one backend supports the model" do
        before do
          registry.register(:backend1, unsupported)
          registry.register(:backend2, supported)
        end

        it "returns the supported backend" do
          expect(registry.guess_from_definition!(definition)).to eq supported
        end
      end

      context "and multiple backends support the model" do
        before do
          registry.register(:backend1, unsupported)
          registry.register(:backend2, supported)
          registry.register(:backend3, supported)
        end

        it "raises a BackendMatch error" do
          expect { registry.guess_from_definition!(definition) }
            .to raise_error(Importu::BackendMatchError)
        end
      end

      context "and a backend raises an exception during checking" do
        let(:broken) { Class.new { def self.supported_by_definition?(*); raise :hell; end } }

        before do
          registry.register(:backend1, broken)
          registry.register(:backend2, unsupported)
          registry.register(:backend3, supported)
        end

        it "ignores the backend" do
          expect(registry.guess_from_definition!(definition)).to eq supported
        end
      end
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

    it "registers the backend" do
      registry.register(:backend1, backend1)
      expect(registry.lookup(:backend1)).to eq backend1
    end

    it "returns the backend that was registered" do
      expect(registry.register(:backend1, backend1)).to eq backend1
    end

    it "allows registering multiple backends" do
      registry.register(:backend1, backend1)
      registry.register(:backend2, backend2)
      expect(registry.lookup(:backend1)).to eq backend1
      expect(registry.lookup(:backend2)).to eq backend2
    end
  end

end
