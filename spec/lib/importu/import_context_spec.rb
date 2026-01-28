# frozen_string_literal: true
require "spec_helper"

require "importu/converter_context"
require "importu/definition"
require "importu/exceptions"

RSpec.describe Importu::ConverterContext do
  subject(:context) do
    described_class.with_config(**definition.config).new(data)
  end

  let(:definition) { Class.new(Importu::Definition) }

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

  describe "field cross-references" do
    context "when a field converter references another field" do
      let(:definition) do
        Class.new(super()) do
          field :first_name
          field :last_name
          field :full_name, abstract: true do
            "#{field_value(:first_name)} #{field_value(:last_name)}"
          end
        end
      end

      let(:data) { { "first_name" => "Arthur", "last_name" => "Dent" } }

      it "can access other field values" do
        expect(context.field_value(:full_name)).to eq "Arthur Dent"
      end
    end

    context "when a field references a field with a converter" do
      let(:definition) do
        Class.new(super()) do
          field :price, &convert_to(:decimal)
          field :quantity, &convert_to(:integer)
          field :total, abstract: true do
            field_value(:price) * field_value(:quantity)
          end
        end
      end

      let(:data) { { "price" => "19.99", "quantity" => "3" } }

      it "receives the converted value, not raw" do
        expect(context.field_value(:total)).to eq BigDecimal("59.97")
      end
    end

    context "when a referenced field is missing" do
      let(:definition) do
        Class.new(super()) do
          field :first_name
          field :last_name
          field :full_name, abstract: true do
            "#{field_value(:first_name)} #{field_value(:last_name)}"
          end
        end
      end

      let(:data) { { "first_name" => "Arthur" } }

      it "raises MissingField for the referenced field" do
        expect { context.field_value(:full_name) }
          .to raise_error(Importu::MissingField)
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
