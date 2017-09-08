require "importu/exceptions"
require "importu/importer"

# Implement the following in specs that use this example:
#
#   subject(:source) { described_class.new(input, importer_class.config) }
#   let(:importer_class) { Class.new(Importu::Importer) }
#
RSpec.shared_examples "importer source" do |format, exclude: []|
  describe "#initialize" do
    unless exclude.include?(:empty_file)
      context "when input file is blank" do
        let(:input) { infile("source-empty-file", format) }

        it "raises an InvalidInput exception" do
          expect { source }.to raise_error Importu::InvalidInput
        end
      end
    end

    unless exclude.include?(:malformed)
      context "when input file is malformed" do
        let(:input) { infile("source-malformed", format) }

        it "raises an InvalidInput exception" do
          expect { source }.to raise_error Importu::InvalidInput
        end
      end
    end
  end

  describe "#rows" do
    unless exclude.include?(:no_records)
      context "when input has no rows" do
        let(:input) { infile("source-no-records", format) }

        it "treats file as having 0 rows" do
          expect(source.rows.count).to eq 0
        end
      end
    end

    unless exclude.include?(:empty_records)
      context "when input contains empty rows" do
        let(:input) { infile("source-empty-records", format) }

        it "treats empty rows as existing (albeit invalid)" do
          expect(source.rows.count).to eq 2
        end
      end
    end

    context "when input contains multiple valid rows" do
      let(:input) { infile("books1", format) }

      it "returns rows parsed from source data" do
        expect(source.rows.count).to eq 3
      end
    end
  end

  describe "Importer#records (usable as a record source?)" do
    subject(:importer) { importer_class.new(source) }
    let(:importer_class) { Class.new(super()) { include BookImporterDefinition } }

    context "when source data is valid" do
      let(:input) { infile("books1", format) }

      it "returns records parsed from source data" do
        expected_record_json!("books1", importer.records)
      end

      it "returns same records on subsequent invocations (rewinds)" do
        previous_count = importer.records.count
        expect(importer.records.count).to eq previous_count
      end
    end
  end

  describe "Importer#import! (verifies entire flow)" do
    subject(:importer) { importer_class.new(source) }
    let(:importer_class) do
      stub_const("Book", Class.new)

      Class.new(super()) do
        model "Book", backend: :dummy
        include BookImporterDefinition
      end
    end

    context "when source data is valid" do
      let(:input) { infile("books1", format) }

      it "returns a summary with expected results" do
        summary = importer.import!
        expected_summary_json!("books1", summary)
      end
    end
  end
end
