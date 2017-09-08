require "spec_helper"

require "importu/converter_context"
require "importu/converters"
require "importu/definition"
require "importu/record"

RSpec.describe Importu::Record do
  subject(:record) { Importu::Record.new(data, context, definition.config) }
  let(:context) { Importu::ConverterContext.with_config(definition.config) }
  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  let(:data) { Hash.new }

  it "includes Enumerable" do
    expect(record).to be_a_kind_of(Enumerable)
  end

  describe "#data" do
    let(:data) { { "foo" => "bar" } }

    it "returns the data used during construction" do
      expect(record.data).to eq data
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
  end
end
