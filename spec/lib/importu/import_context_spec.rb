require "spec_helper"

require "importu/converters"
require "importu/exceptions"
require "importu/import_context"

RSpec.describe Importu::ImportContext do
  subject(:context) do
    Importu::ImportContext.with_config(definition.config).new(data)
  end

  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  let(:data) { {} }

  describe "#field_value" do
    let(:definition) do
      Class.new(super()) do
        field :field1, required: true, &convert_to(:integer)
      end
    end

    let(:data) { { "field1" => "73" } }

    it "returns the field value after applying the converter" do
      expect(context.field_value(:field1)).to eq 73
    end

    context "when a definition doesn't exist for the field" do
      it "raises an InvalidDefinition error" do
        expect { context.field_value(:nonexistent_field) }
          .to raise_error(Importu::InvalidDefinition)
      end
    end

    context "when the converted value is nil" do
      let(:data) { { "field1" => nil } }

      context "and the field is required" do
        let(:definition) { Class.new(super()) { field :field1, required: true } }

        it "raises a MissingField error" do
          expect { context.field_value(:field1) }
            .to raise_error(Importu::MissingField)
        end

        context "and a default is defined on the field" do
          let(:definition) { Class.new(super()) { field :field1, default: :beep } }

          it "raises a MissingField error" do
            expect { context.field_value(:field1) }
              .to raise_error(Importu::MissingField)
          end
        end
      end

      context "and the field is not required" do
        let(:definition) { Class.new(super()) { field :field1, required: false } }

        it "returns nil" do
          expect(context.field_value(:field1)).to be nil
        end

        context "annd a default is defined on the field" do
          let(:definition) { Class.new(super()) { field :field1, default: :beep } }

          it "returns the default value" do
            expect(context.field_value(:field1)).to eq :beep
          end
        end
      end
    end

    context "when converter raises an ArgumentError" do
      let(:definition) do
        Class.new(super()) do
          converter(:ash) {|*| raise ArgumentError, "sawdust" }
          field :field1, &convert_to(:ash)
        end
      end

      it "raises a FieldParseError error" do
        expect { context.field_value(:field1) }
          .to raise_error(Importu::FieldParseError)
      end

      it "includes the original error message" do
        expect { context.field_value(:field1) }
          .to raise_error(Importu::FieldParseError)
          .with_message(/sawdust/)
      end
    end

    context "when converter raises an unexpected error" do
      let(:definition) do
        Class.new(super()) do
          converter(:rubble) {|*| raise StandardError, "you did what?!" }
          field :field1, &convert_to(:rubble)
        end
      end

      it "raises the unexpected exception" do
        expect { context.field_value(:field1) }
          .to raise_error(StandardError)
      end
    end
  end

  describe "#raw_value" do
    let(:definition) { Class.new(super()) { field :field1 } }
    let(:data) { { "field1" => "zippy" } }

    it "returns the data associated with the field" do
      expect(context.raw_value(:field1)).to eq data["field1"]
    end

    context "when a definition doesn't exist for the field" do
      it "raises an InvalidDefinition error" do
        expect { context.raw_value(:nonexistent_field) }
          .to raise_error(Importu::InvalidDefinition)
      end
    end

    context "when data is nil for the field" do
      let(:data) { { "field1" => nil } }

      it "returns nil" do
        expect(context.raw_value(:field1)).to be nil
      end
    end

    context "when the field does not exist in data hash" do
      let(:data) { {} }

      it "returns nil" do
        expect(context.raw_value(:field1)).to be nil
      end
    end
  end

end
