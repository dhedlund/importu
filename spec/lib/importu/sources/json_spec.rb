require "spec_helper"

require "importu/sources/json"

RSpec.describe Importu::Sources::JSON do
  subject(:importer) { importer_class.new(StringIO.new(data)) }

  let!(:model) do
    # Plain old ruby object for model, no guessable backend
    stub_const "Book", Class.new
  end

  let(:importer_class) do
    Class.new(Importu::Sources::JSON) do
      model "Book", backend: :dummy
      include BookImporterDefinition
    end
  end

  let(:data) do
    File.read(infile("books1", :json))
  end

  describe "#initialize" do
    context "when input file is blank" do
      let(:data) { "" }

      it "raises an InvalidInput exception" do
        expect { importer }.to raise_error(Importu::InvalidInput)
      end
    end

    context "when root element is not an array" do
      %w({}, "foo", 3, 3.7, false, nil).each do |bad_data|
        context "when root is #{bad_data}" do
          let(:data) { bad_data }
          it "raises InvalidInput exception" do
            expect { importer }.to raise_error(Importu::InvalidInput)
          end
        end
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
      let(:data) { "[]" }

      it "treats file as having 0 records" do
        expect(importer.records.count).to eq 0
      end
    end

    context "when input contains empty record objects" do
      let(:data) { "[{},{}]" }

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
