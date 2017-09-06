require "spec_helper"

require "importu/converters"
require "importu/definition"
require "importu/record"

RSpec.describe Importu::Record do
  subject(:record) { Importu::Record.new(data, raw_data, definition.config) }
  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  let(:data) { Hash.new }
  let(:raw_data) { Hash.new }

  it "includes Enumerable" do
    expect(record).to be_a_kind_of(Enumerable)
  end

  describe "#data" do
    let(:data) { { "foo" => "bar" } }

    it "returns the data used during construction" do
      expect(record.data).to eq data
    end
  end

  describe "#raw_data" do
    let(:raw_data) { "this,is\tsome_raw_data\n" }

    it "returns the raw_data used during construction" do
      expect(record.raw_data).to eq raw_data
    end
  end

  describe "#field_definitions" do
    let(:definition) { Class.new(super()) { field :foo } }

    it "returns the field definitions defined in importer on construction" do
      expect(record.field_definitions).to include(:foo)
    end
  end

  describe "#record_hash" do
    it "tries to generate a record hash on first access" do
      expected = { foo: 1, bar: 2 }
      expect(record).to receive(:generate_record_hash).and_return(expected)
      expect(record.record_hash).to eq expected
    end

    it "should not try to regenerate record hash no subsequent access" do
      expected = { foo: 1, bar: 2 }
      expect(record).to receive(:generate_record_hash).once.and_return(expected)
      record.record_hash
      expect(record.record_hash).to eq expected
    end

    it "is aliased from #to_hash" do
      expect(record).to receive(:record_hash).and_return(:called)
      expect(record.to_hash).to eq :called
    end

    it "is delegated from #keys" do
      expect(record).to delegate(:keys).to(:record_hash)
    end

    it "is delegated from #values" do
      expect(record).to delegate(:values).to(:record_hash)
    end

    it "is delegated from #each" do
      expect(record).to delegate(:each).to(:record_hash)
    end

    it "is delegated from #[]" do
      expect(record).to delegate(:[]).to(:record_hash)
    end

    it "is delegated from #key?" do
      expect(record).to delegate(:key?).to(:record_hash)
    end

    describe "#convert" do
      context "with a :default option" do
        it "returns data value if data value not nil" do
          definition.converter(:clean) { "value1" }
          expect(record.convert(:field1, :clean, default: "foobar")).to eq "value1"
        end

        it "returns default value if data value is nil" do
          definition.converter(:clean) { nil }
          expect(record.convert(:field1, :clean, default: "foobar")).to eq "foobar"
        end

        it "returns default value if data field is missing and not required" do
          definition.converter(:clean) { raise Importu::MissingField, "field1" }
          expect(record.convert(:field1, :clean, default: "foobar")).to eq "foobar"
        end

        it "raises an exception if data field is missing and is required" do
          definition.converter(:clean) { raise Importu::MissingField, "field1" }
          expect { record.convert(:field1, :clean, default: "foobar", required: true) }.to raise_error(Importu::MissingField)
        end
      end
    end

  end
end
