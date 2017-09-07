require "spec_helper"

require "importu/converters"
require "importu/exceptions"
require "importu/import_context"

RSpec.describe Importu::ImportContext do
  subject(:context) do
    Importu::ImportContext.new({}, {
      fields: {},
      converters: definition.config[:converters]
    })
  end

  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  describe "#convert" do
    context "with a :default option" do
      it "returns data value if data value not nil" do
        definition.converter(:clean) { "value1" }
        expect(context.convert(:field1, :clean, default: "foobar")).to eq "value1"
      end

      it "returns default value if data value is nil" do
        definition.converter(:clean) { nil }
        expect(context.convert(:field1, :clean, default: "foobar")).to eq "foobar"
      end

      it "returns default value if data field is missing and not required" do
        definition.converter(:clean) { raise Importu::MissingField, "field1" }
        expect(context.convert(:field1, :clean, default: "foobar")).to eq "foobar"
      end

      it "raises an exception if data field is missing and is required" do
        definition.converter(:clean) { raise Importu::MissingField, "field1" }
        expect { context.convert(:field1, :clean, default: "foobar", required: true) }
          .to raise_error(Importu::MissingField)
      end
    end
  end

end
