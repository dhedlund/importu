require "importu/exceptions"
require "importu/importer"
require "importu/summary"

# Implement the following in specs that use this example:
#
#   subject(:source) { described_class.new(input, source_config) }
#   let(:importer_class) { Class.new(Importu::Importer) }
#   let(:source_config) { importer_class.config[:sources][:csv] }
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
      let(:input) { infile("books-valid", format) }

      it "returns rows parsed from source data" do
        expect(source.rows.count).to eq 3
      end
    end
  end

  describe "#write_errors" do
    subject(:source) { described_class.new(infile("books-valid", format), source_config) }
    let(:importer_class) { Class.new(super()) { include BookImporterDefinition } }

    context "when there are no errors during import" do
      let(:summary) { Importu::Summary.new }

      it "doesn't try to generate a file, but returns nil" do
        expect(source.write_errors(summary)).to be_nil
      end
    end

    context "when there are errors during import" do
      let(:summary) do
        Importu::Summary.new.tap do |summary|
          summary.record(:invalid, index: 1, errors: ["foo was invalid"])
          summary.record(:invalid, index: 2, errors: ["foo was invalid", "bar was invalid"])
        end
      end

      it "returns a rewoundfile handle/io" do
        errfile = source.write_errors(summary)
        expect(errfile).to respond_to(:readline)
        expect(errfile.pos).to eq 0
      end

      it "records errors to '_errors' field with source data" do
        errfile = source.write_errors(summary)
        new_source = described_class.new(errfile, source_config)

        expect(new_source.rows.map {|r| r["_errors"] }).to eq [
          nil,                                # 0
          "foo was invalid",                  # 1
          "foo was invalid, bar was invalid", # 2
        ]

        # Everything except "_errors" should match original input
        expect(new_source.rows.map {|row| row.reject {|k,v| k == "_errors" } })
          .to eq source.rows.to_a
      end

      it "clears any existing '_errors' values in source data" do
        errfile = source.write_errors(summary)
        source2 = described_class.new(errfile, source_config)

        summary2 = Importu::Summary.new.tap do |summary|
          summary.record(:invalid, index: 0, errors: ["baz was invalid"])
        end

        errfile2 = source2.write_errors(summary2)
        source3 = described_class.new(errfile2, source_config)

        expect(source3.rows.map {|r| r["_errors"] }).to eq [
          "baz was invalid", # 0
          nil,               # 1
          nil,               # 2
        ]
      end

      it "does not affect original source data" do
        expect { source.write_errors(summary) }
          .to_not change { source.rows.to_a }
      end

      it "supports only writing records with errors" do
        errfile = source.write_errors(summary, only_errors: true)
        new_source = described_class.new(errfile, source_config)
        expect(new_source.rows.map {|r| r["_errors"] }).to eq [
          # nil,                              # 0, excluded
          "foo was invalid",                  # 1
          "foo was invalid, bar was invalid", # 2
        ]
      end
    end
  end

  describe "Importer#records (usable as a record source?)" do
    subject(:importer) { importer_class.new(source) }
    let(:importer_class) { Class.new(super()) { include BookImporterDefinition } }

    context "when source data is valid" do
      let(:input) { infile("books-valid", format) }

      it "returns records parsed from source data" do
        expected_record_json!("books-valid", importer.records)
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
      let(:input) { infile("books-valid", format) }

      it "returns a summary with expected results" do
        summary = importer.import!
        expected_summary_json!("books-valid", summary)
      end
    end
  end
end
