require "spec_helper"

RSpec.describe Importu::Backends::Middleware::DuplicateManagerProxy do
  subject(:middleware) { described_class.new(dummy_backend, backend_config) }

  let(:dummy_backend) { DummyBackend.new(backend_config) }
  let(:backend_config) { definition.config[:backend] }

  let(:definition) do
    Class.new do
      extend Importu::Definition
      fields :foo, :bar, :baz
      find_by :foo, :bar
    end
  end

  describe "#create" do
    it "returns the status and object from the backend" do
      status, object = middleware.create(foo: 1, bar: 1, baz: 1)
      expect(status).to eq :created
      expect(object).to include(foo: 1, bar: 1, baz: 1)
    end

    it "perform duplicate detection on the record" do
      middleware.create(foo: 1, bar: 1, baz: 1)
      expect { middleware.create(foo: 2, bar: 1, baz: 2) } # :baz is a dupe find_by
        .to raise_error(Importu::DuplicateRecord)
    end

    it "records created object for subsequent dupe detection" do
      middleware.create(foo: 1, bar: 1, baz: 1)
      expect { middleware.create(foo: 2, bar: 1, baz: 2) }
        .to raise_error(Importu::DuplicateRecord)
    end
  end

  describe "#update" do
    it "returns the status and object from the backend" do
      _, object = dummy_backend.create(foo: 1, bar: 1, baz: 1)
      status, new_object = middleware.update({foo: 2, bar: 2, baz: 2}, object)

      expect(status).to eq :updated
      expect(new_object).to include(foo: 2, bar: 2, baz: 2)
    end

    it "perform duplicate detection on the record" do
      _status, object = middleware.create(foo: 1, bar: 1, baz: 1)

      expect(dummy_backend).to_not receive(:update)
      expect { middleware.update({foo: 1, bar: 2, baz: 2}, object) } # :foo is a dupe
        .to raise_error(Importu::DuplicateRecord)
    end

    it "performs duplicate detection on object" do
      # Existing db record, never accessed through dupe detector
      _status, object = dummy_backend.create(foo: 1, bar: 1, baz: 1)

      # Update via :foo, first encounter of k/v and first encounter of object
      expect { middleware.update({foo: 1, bar: 2, baz: 3}, object) }.to_not raise_error

      # Update via :bar, first encounter of k/v, but second encounter of object
      expect { middleware.update({foo: 2, bar: 1, baz: 3}, object) }
        .to raise_error(Importu::DuplicateRecord)
    end
  end

end
