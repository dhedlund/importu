require "spec_helper"

require "importu/exceptions"

RSpec.describe Importu::ImportuException do
  subject(:exception) { Importu::ImportuException.new }

  it "#name should return 'ImportuException" do
    expect(exception.name).to eq "ImportuException"
  end

  describe Importu::InvalidInput do
    subject(:exception) { Importu::InvalidInput.new }

    it "should be a subclass of Importu::ImportuException" do
      exception.class.ancestors.include?(Importu::ImportuException)
    end

    it "#name should return 'InvalidInput'" do
      expect(exception.name).to eq "InvalidInput"
    end
  end

  describe Importu::InvalidRecord do
    subject(:exception) { Importu::InvalidRecord.new }

    it "should be a subclass of Importu::ImportuException" do
      exception.class.ancestors.include?(Importu::ImportuException)
    end

    it "#name should return 'InvalidRecord'" do
      expect(exception.name).to eq "InvalidRecord"
    end
  end

  describe Importu::FieldParseError do
    subject(:exception) { Importu::FieldParseError.new }

    it "should be a subclass of Importu::InvalidRecord" do
      exception.class.ancestors.include?(Importu::InvalidRecord)
    end

    it "#name should return 'FieldParseError'" do
      expect(exception.name).to eq "FieldParseError"
    end
  end

  describe Importu::MissingField do
    let(:definition) { { name: "foo_field_1", label: "Field 1" } }
    subject(:exception) { Importu::MissingField.new(definition) }

    it "should be a subclass of Importu::InvalidRecord" do
      exception.class.ancestors.include?(Importu::InvalidRecord)
    end

    it "#name should return 'MissingField'" do
      expect(exception.name).to eq "MissingField"
    end

    it "#definition should return the definition passed during construction" do
      expect(exception.definition).to eq definition
    end

    describe "#message" do
      it "should mention a missing field" do
        expect(exception.message).to match(/missing field/i)
      end

      context "field definition has a label" do
        let(:definition) { { label: "Field 2" } }
        it "mentions missing field's label" do
          expect(exception.message).to match(/Field 2/)
        end
      end

      context "field definition is missing a label" do
        let(:definition) { { name: "foo_field_2" } }

        it "mentions missing field's name" do
          expect(exception.message).to match(/foo_field_2/)
        end
      end
    end
  end

  describe Importu::DuplicateRecord do
    subject(:exception) { Importu::DuplicateRecord.new }

    it "should be a subclass of Importu::InvalidRecord" do
      exception.class.ancestors.include?(Importu::InvalidRecord)
    end

    it "#name should return 'DuplicateRecord'" do
      expect(exception.name).to eq "DuplicateRecord"
    end
  end

end
