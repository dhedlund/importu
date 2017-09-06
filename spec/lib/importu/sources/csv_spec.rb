require "spec_helper"

require "importu/importer"
require "importu/sources/csv"

RSpec.describe Importu::Sources::CSV do
  subject(:importer) { importer_class.new(source) }
  let(:source) { described_class.new(StringIO.new(data)) }

  let!(:model) do
    # Plain old ruby object for model, no guessable backend
    stub_const "Book", Class.new
  end

  let(:importer_class) do
    Class.new(BookImporter) do
      model "Book", backend: :dummy
    end
  end

  let(:data) do
    File.read(infile("books1", :csv))
  end

  describe "#initialize" do
    context "with custom csv options" do
      let(:csv_options) { { skip_blanks: false } }
      let(:data) { super() + "\n\n\n" }

      it "allows overriding csv options" do
        source = described_class.new(StringIO.new(data), csv_options: csv_options)
        custom_importer = importer_class.new(source)
        expect(custom_importer.records.count).to be > importer.records.count
      end
    end

    context "when input file is blank" do
      let(:data) { "" }

      it "raises an InvalidInput exception" do
        expect { importer }.to raise_error(Importu::InvalidInput)
      end
    end
  end

  describe "#records" do
    it "returns records parsed from source data" do
      # Dump and re-parse to ensure everything is JSON types w/ string keys
      record_json = JSON.parse(JSON.dump(importer.records.map(&:to_hash)))
      expect(record_json).to eq expected_record_json("books1")
    end

    context "when input has header but no records" do
      let(:data) { super().lines.first }

      it "treats file as having no records" do
        expect(importer.records.count).to eq 0
      end
    end

    it "returns same records on subsequent invocations (rewinds)" do
      expect(importer.records.count).to eq importer.records.count
    end
  end

  describe "#import!" do
    it "returns a summary of results" do
      summary = importer.import!
      expect(summary.created).to eq 3
      expect(summary.total).to eq 3
    end

    context "when a backend cannot be guessed from the model" do
      let(:importer_class) do
        Class.new(super()) do
          model "Book", backend: nil
        end
      end

      it "raises an error" do
        importer # Ensure exception doesn't happen at initialization
        expect { importer.import! }.to raise_error(Importu::BackendMatchError)
      end
    end
  end

end