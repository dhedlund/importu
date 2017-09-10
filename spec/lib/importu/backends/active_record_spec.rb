require "spec_helper"

require "importu/backends/active_record"
require "importu/importer"
require "importu/sources/csv"

RSpec.describe "ActiveRecord Backend", :active_record do
  let(:source) { Importu::Sources::CSV.new(infile("books1", :csv)) }
  subject(:importer) { importer_class.new(source) }

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
      summary = importer.import!
      expected_summary_json!("books1", summary)
    end

    it "correctly saves imported data in the model" do
      importer.import!
      expect(models_json).to match_array expected_model_json("books1")
    end

    context "when definition includes non-abstract fields not on model" do
      let(:importer_class) { Class.new(super()) { fields(:foo, :bar) { "blah" } } }

      it "raises an UnassignableFields error" do
        expect { importer.import! }.to raise_error(Importu::UnassignableFields)
      end
    end

    context "when creating records" do
      context "when create actions are not allowed" do
        let(:importer_class) { Class.new(super()) { allow_actions :update } }

        it "marks each record creation as inavlid" do
          summary = importer.import!
          expect(summary.created).to eq 0
          expect(summary.invalid).to eq 3
        end
      end
    end

    context "when updating records" do
      before { importer.import! }

      context "and there are no changes" do
        it "marks each record as unchanged" do
          summary = importer.import!
          expect(summary.unchanged).to eq 3
        end
      end

      context "when updates actions are not allowed" do
        let(:importer_class) { Class.new(super()) { allow_actions :create } }

        it "marks each record update as inavlid" do
          summary = importer.import!
          expect(summary.updated).to eq 0
          expect(summary.invalid).to eq 3
        end
      end
    end

    context "when a before_save callback is defined" do
      let(:importer_class) do
        Class.new(super()) do
          before_save { object.title = object.title.upcase }
        end
      end

      it "runs callback before saving" do
        importer.import!
        Book.first.title == Book.first.title.upcase
      end
    end
  end

end
