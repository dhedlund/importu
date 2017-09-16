require "spec_helper"

require "importu/backends/middleware/enforce_allowed_actions"
require "importu/definition"

RSpec.describe Importu::Backends::Middleware::EnforceAllowedActions do
  subject(:middleware) { described_class.new(dummy_backend, backend_config) }

  let(:dummy_backend) { DummyBackend.new(backend_config) }
  let(:backend_config) { definition.config[:backend] }

  let(:definition) do
    Class.new(Importu::Definition) do
      allow_actions nil
      fields :foo, :bar, :baz
    end
  end

  describe "#create" do
    context "when :create action is allowed" do
      let(:definition) { Class.new(super()) { allow_actions :create } }

      it "returns the status and object from the backend" do
        status, object = middleware.create(foo: 1, bar: 1, baz: 1)
        expect(status).to eq :created
        expect(object).to include(foo: 1, bar: 1, baz: 1)
      end
    end

    context "when :create action is not allowed" do
      it "raises an InvalidError exception" do
        expect { middleware.create(foo: 1, bar: 1, baz: 1) }
          .to raise_error(Importu::InvalidRecord)
      end
    end
  end

  describe "#update" do
    let(:object) { _, object = dummy_backend.create(foo: 1, bar: 1, baz: 1); object }

    context "when :update action is allowed" do
      let(:definition) { Class.new(super()) { allow_actions :update } }

      it "returns the status and object from the backend" do
        status, new_object = middleware.update({foo: 2, bar: 2, baz: 2}, object)
        expect(status).to eq :updated
        expect(new_object).to include(foo: 2, bar: 2, baz: 2)
      end
    end

    context "when :update action is not allowed" do
      it "raises an InvalidError exception" do
        expect { middleware.create(foo: 1, bar: 1, baz: 1) }
          .to raise_error(Importu::InvalidRecord)
      end
    end
  end

end
