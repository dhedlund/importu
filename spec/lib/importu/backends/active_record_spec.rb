require "spec_helper"

require "importu/backends/active_record"
require "importu/importer/csv"

RSpec.describe "ActiveRecord Backend", :active_record do
  subject(:importer) { importer_class.new(infile("books1", :csv)) }

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
    let(:models_json) do
      serialized = Book.all.to_json(except: [:id, :created_at, :updated_at])
      JSON.parse(serialized)
    end


    it "imports new book records" do
      expect { importer.import! }.to change { Book.count }.by(3)
    end

    it "correctly summarizes import statistics" do
      importer.import!
      expect(importer.summary.to_hash.stringify_keys)
        .to eq expected_summary_json("books1")
    end

    it "correctly saves imported data in the model" do
      importer.import!
      expect(models_json).to match_array expected_model_json("books1")
    end
  end

end
