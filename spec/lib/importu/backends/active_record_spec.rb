require "spec_helper"

RSpec.describe "ActiveRecord Backend", :activerecord do
  let(:fixture_path) { File.expand_path("../../../../fixtures", __FILE__) }
  let(:infile) { File.join(fixture_path, "books.csv") }

  subject(:importer) { importer_class.new(infile) }

  let!(:model) do
    stub_const "Book", Class.new(ActiveRecord::Base)
  end

  let(:importer_class) do
    Class.new(Importu::Importer::Csv) do
      model "Book"
      fields :title, :author, :isbn10
      field :pages, &convert_to(:integer)
      field :release_date, &convert_to(:date)
    end
  end

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
