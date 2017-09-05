require "spec_helper"

require "importu/importer/xml"

RSpec.describe Importu::Importer::XML do
  subject(:importer) { importer_class.new(StringIO.new(data)) }

  let!(:model) do
    # Plain old ruby object for model, no guessable backend
    stub_const "Book", Class.new
  end

  let(:importer_class) do
    Class.new(Importu::Importer::XML) do
      model "Book", backend: :dummy
      include BookImporterDefinition
      records_xpath '//book'
    end
  end

  let(:data) do
    File.read(infile("books1", :xml))
  end

  describe "#initialize" do
    context "when input file is blank" do
      let(:data) { "" }

      it "raises an InvalidInput exception" do
        expect { importer }.to raise_error Importu::InvalidInput
      end
    end

    context "when input file is malformed" do
      let(:data) { '<?xml version="1.0" encoding="UTF-8"?><boo' }

      it "raises an InvalidInput exception" do
        expect { importer }.to raise_error Importu::InvalidInput
      end
    end
  end

  describe "#records" do
    it "returns records parsed from source data" do
      # Dump and re-parse to ensure everything is JSON types w/ string keys
      record_json = JSON.parse(JSON.dump(importer.records.map(&:to_hash)))
      expect(record_json).to eq expected_record_json("books1")
    end

    context "when input has no records" do
      let(:data) { '<?xml version="1.0" encoding="UTF-8"?><books />' }

      it "treats file as having 0 records" do
        expect(importer.records.count).to eq 0
      end
    end

    context "when input contains empty record objects" do
      let(:data) do
        '<?xml version="1.0" encoding="UTF-8"?>' +
        '<books><book /><book></book></books>'
      end

      it "treats empty records as existing (albeit invalid)" do
        expect(importer.records.count).to eq 2
      end
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
