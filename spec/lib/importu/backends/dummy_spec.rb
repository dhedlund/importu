require "spec_helper"

RSpec.describe "Dummy Backend" do
  let(:fixture_path) { File.expand_path("../../../../fixtures", __FILE__) }
  let(:infile) { File.join(fixture_path, "books.csv") }

  subject(:importer) { import_class.new(infile) }

  class WeeBook
    # Plain old ruby object, no guessable backend
  end

  describe "#import!" do
    context "when a backend cannot be guessed from the model" do
      let(:import_class) do
        Class.new(Importu::Importer::Csv) do
          model "DummyBook"
          fields :title, :author, :isbn10
          field :pages, &convert_to(:integer)
          field :release_date, &convert_to(:date)
        end
      end

      it "raises an error" do
        expect { importer.import! }.to raise_error(Importu::BackendMatchError)
      end
    end
  end

end
