require "spec_helper"

RSpec.describe "ActiveRecord Backend", :activerecord do
  let(:fixture_path) { File.expand_path("../../../../fixtures", __FILE__) }
  let(:infile) { File.join(fixture_path, "books.csv") }

  class BookImporter < Importu::Importer::Csv
    model "Book"
    fields :title, :author, :isbn10
    field :pages, &convert_to(:integer)
    field :release_date, &convert_to(:date)
  end

  subject(:importer) { BookImporter.new(infile) }

  around(:each) do |example|
    require "database_cleaner"
    DatabaseCleaner.cleaning { example.run }
  end

  describe "#import!" do
    it "imports new book records" do
      expect { importer.import! }.to change { Book.count }.by(3)
    end

    it "records records as created" do
      importer.import!
      expect(importer.created).to eq 3
      expect(importer.total).to eq 3
    end
  end

end
