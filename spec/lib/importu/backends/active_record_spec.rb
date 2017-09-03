require "spec_helper"

require "importu/backends/active_record"
require "importu/importer/csv"

RSpec.describe "ActiveRecord Backend", :active_record do
  subject(:importer) { importer_class.new(csv_infile("books")) }

  let!(:model) do
    stub_const("Book", Class.new(ActiveRecord::Base) do
      serialize :authors, Array
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
