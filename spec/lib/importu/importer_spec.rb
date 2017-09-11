require "spec_helper"

require "importu/importer"
require "importu/sources/ruby"

RSpec.describe Importu::Importer do
  subject(:importer) { importer_class.new(source) }

  let(:source) { Importu::Sources::Ruby.new(data) }

  let(:data) do
    [
      { "animal" => "llama",    "name" => "Nathan",   "age" => "3" },
      { "animal" => "aardvark", "name" => "Stella",   "age" => "2" },
      { "animal" => "crow",     "name" => "Hamilton", "age" => "6" },
    ]
  end

  let(:importer_class) do
    Class.new(Importu::Importer) do
      fields :animal, :name, :age, required: true
      field :age, &convert_to(:integer)
    end
  end

  describe "#config" do
    it "returns the configuration of the import definition" do
      expect(importer.config[:fields]).to include(:animal, :name, :age)
    end
  end

  describe "#import!" do
    context "when a backend is specified at initialization" do
      subject(:importer) { importer_class.new(source, backend: backend) }
      let(:backend) { DummyBackend.new(importer_class.config[:backend]) }

      it "uses the backend from initialization" do
        expect(Importu::Importer).to_not receive(:backend_registry)
        expect(backend).to receive(:create).exactly(3).times.and_call_original
        importer.import!
      end
    end

    context "when a backend is not specified at initialization" do
      it "tries to detect backend from the definition" do
        expect(Importu::Importer.backend_registry)
          .to receive(:from_config!).with(importer.config[:backend])
          .and_return(DummyBackend)
        importer.import!
      end
    end
  end

  describe "#records" do
    it "returns the same number of records as source data" do
      expect(importer.records.count).to eq 3
    end

    it "returns record objects with conversions applied" do
      record = importer.records.first
      expect(record.to_hash).to eq({
        animal: "llama", name: "Nathan", age: 3
      })
    end
  end

  describe "#source" do
    it "returns the source provided to importer at initialization" do
      expect(importer.source).to eq source
    end
  end

end
