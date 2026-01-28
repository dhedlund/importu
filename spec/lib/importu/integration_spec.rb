# frozen_string_literal: true

require "spec_helper"

require "importu/backends/active_record"
require "importu/importer"
require "importu/sources/csv"
require "importu/sources/json"
require "importu/sources/xml"

# Integration tests that exercise the full import pipeline across different
# source formats and scenarios. These serve as smoke tests and living
# documentation of the gem's primary use cases.
RSpec.describe "Integration", :active_record do
  let!(:model) do
    stub_const("Book", Class.new(ActiveRecord::Base) do
      serialize :authors, type: Array
      validates :title, :authors, :isbn10, :release_date, presence: true
      validates :isbn10, length: { is: 10 }, uniqueness: true
    end)
  end

  let(:importer_class) do
    Class.new(BookImporter) do
      model "Book"
    end
  end

  around(:each) do |example|
    require "database_cleaner-active_record"
    DatabaseCleaner.cleaning { example.run }
  end

  describe "JSON import updating existing records" do
    let(:source) { Importu::Sources::JSON.new(infile("books-valid", :json)) }
    subject(:importer) { importer_class.new(source) }

    context "when records already exist" do
      before { importer.import! }

      it "finds and updates existing records" do
        summary = importer.import!
        expect(summary.created).to eq 0
        expect(summary.updated).to eq 0
        expect(summary.unchanged).to eq 3
      end

      context "when data has changed" do
        let(:modified_source) do
          data = JSON.parse(File.read(infile("books-valid", :json)))
          data[0]["title"] = "The Ruby Programming Language (2nd Edition)"
          Importu::Sources::JSON.new(StringIO.new(JSON.generate(data)))
        end

        it "updates the changed record" do
          modified_importer = importer_class.new(modified_source)
          summary = modified_importer.import!

          expect(summary.created).to eq 0
          expect(summary.updated).to eq 1
          expect(summary.unchanged).to eq 2

          updated_book = Book.find_by(isbn10: "0596516177")
          expect(updated_book.title).to eq "The Ruby Programming Language (2nd Edition)"
        end
      end
    end
  end

  describe "XML import with duplicate detection" do
    let(:source_config) do
      Class.new(Importu::Definition) { source :xml, records_xpath: "//book" }
        .config[:sources][:xml]
    end

    let(:xml_with_duplicates) do
      <<~XML
        <?xml version="1.0"?>
        <books>
          <book isbn10="0596516177" title="First" author="Author A" release_date="2008-01-01" pages="100" />
          <book isbn10="1449355978" title="Second" author="Author B" release_date="2013-05-01" pages="200" />
          <book isbn10="0596516177" title="Duplicate" author="Author C" release_date="2010-01-01" pages="300" />
        </books>
      XML
    end

    let(:source) { Importu::Sources::XML.new(StringIO.new(xml_with_duplicates), **source_config) }
    subject(:importer) { importer_class.new(source) }

    it "creates the first record and marks duplicate as invalid" do
      summary = importer.import!

      expect(summary.created).to eq 2
      expect(summary.invalid).to eq 1
      expect(summary.validation_errors.keys).to include(match(/duplicate/i))
    end
  end

  describe "mixed create/update with error reporting" do
    let(:source) { Importu::Sources::CSV.new(infile("books-valid", :csv)) }
    subject(:importer) { importer_class.new(source) }

    context "when some records exist and others are new" do
      before do
        # Create only the first book
        Book.create!(
          isbn10: "0596516177",
          title: "Old Title",
          authors: ["Old Author"],
          release_date: Date.new(2008, 1, 1),
          pages: 100
        )
      end

      it "creates new records and updates existing ones" do
        summary = importer.import!

        expect(summary.created).to eq 2
        expect(summary.updated).to eq 1
        expect(summary.unchanged).to eq 0
        expect(summary.invalid).to eq 0

        expect(Book.count).to eq 3
        updated_book = Book.find_by(isbn10: "0596516177")
        expect(updated_book.title).to eq "The Ruby Programming Language"
      end
    end

    context "when some records fail validation" do
      let(:importer_class) do
        Class.new(super()) do
          # Force first record to have invalid ISBN (apply trimmed first to
          # handle whitespace in source data)
          field :isbn10 do
            value = trimmed(:isbn10)
            value == "0596516177" ? "bad" : value
          end
        end
      end

      it "reports validation errors while processing valid records" do
        summary = importer.import!

        expect(summary.created).to eq 2
        expect(summary.invalid).to eq 1
        expect(summary.validation_errors.keys).to include(match(/isbn10/i))
      end
    end

    context "when actions are restricted" do
      context "with only create allowed" do
        let(:importer_class) do
          Class.new(super()) { allow_actions :create }
        end

        before do
          Book.create!(
            isbn10: "0596516177",
            title: "Existing",
            authors: ["Author"],
            release_date: Date.new(2008, 1, 1)
          )
        end

        it "creates new records but marks updates as invalid" do
          summary = importer.import!

          expect(summary.created).to eq 2
          expect(summary.invalid).to eq 1
          expect(summary.validation_errors.keys).to include(match(/update.*not allowed/i))
        end
      end

      context "with only update allowed" do
        let(:importer_class) do
          Class.new(super()) { allow_actions :update }
        end

        before do
          Book.create!(
            isbn10: "0596516177",
            title: "Existing",
            authors: ["Author"],
            release_date: Date.new(2008, 1, 1)
          )
        end

        it "updates existing records but marks creates as invalid" do
          summary = importer.import!

          expect(summary.created).to eq 0
          expect(summary.updated).to eq 1
          expect(summary.invalid).to eq 2
          expect(summary.validation_errors.keys).to include(match(/create.*not allowed/i))
        end
      end
    end
  end

  describe "import with before_save hooks" do
    let(:source) { Importu::Sources::JSON.new(infile("books-valid", :json)) }

    let(:importer_class) do
      Class.new(super()) do
        before_save do
          object.title = object.title.upcase
        end
      end
    end

    subject(:importer) { importer_class.new(source) }

    it "applies the hook to all records" do
      importer.import!

      Book.all.each do |book|
        expect(book.title).to eq book.title.upcase
      end
    end
  end
end
