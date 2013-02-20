require 'spec_helper'

describe Importu::ImportuException do
  subject(:exception) { Importu::ImportuException.new }

  it "#name should return 'ImportuException" do
    exception.name.should eq "ImportuException"
  end

  describe Importu::InvalidInput do
    subject(:exception) { Importu::InvalidInput.new }

    it "should be a subclass of Importu::ImportuException" do
      exception.class.ancestors.include?(Importu::ImportuException)
    end

    it "#name should return 'InvalidInput'" do
      exception.name.should eq "InvalidInput"
    end
  end

  describe Importu::InvalidRecord do
    subject(:exception) { Importu::InvalidRecord.new }

    it "should be a subclass of Importu::ImportuException" do
      exception.class.ancestors.include?(Importu::ImportuException)
    end

    it "#name should return 'InvalidRecord'" do
      exception.name.should eq "InvalidRecord"
    end
  end

  describe Importu::FieldParseError do
    subject(:exception) { Importu::FieldParseError.new }

    it "should be a subclass of Importu::InvalidRecord" do
      exception.class.ancestors.include?(Importu::InvalidRecord)
    end

    it "#name should return 'FieldParseError'" do
      exception.name.should eq "FieldParseError"
    end
  end

  describe Importu::MissingField do
    let(:definition) { { :name => "foo_field_1", :label => "Field 1" } }
    subject(:exception) { Importu::MissingField.new(definition) }

    it "should be a subclass of Importu::InvalidRecord" do
      exception.class.ancestors.include?(Importu::InvalidRecord)
    end

    it "#name should return 'MissingField'" do
      exception.name.should eq "MissingField"
    end

    it "#definition should return the definition passed during construction" do
      exception.definition.should eq definition
    end

    describe "#message" do
      it "should mention a missing field" do
        exception.message.should match(/missing field/i)
      end

      context "field definition has a label" do
        let(:definition) { { :label => "Field 2" } }
        it "mentions missing field's label" do
          exception.mesage.should match(/Field 2/)
        end
      end

      context "field definition is missing a label" do
        let(:definition) { { :name => "foo_field_2" } }

        it "mentions missing field's name" do
          exception.message.should match(/foo_field_2/)
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
      exception.name.should eq "DuplicateRecord"
    end
  end

end
