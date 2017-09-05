require "spec_helper"

require "importu/sources/csv"

RSpec.describe "Dummy Backend" do
  subject(:importer) { importer_class.new(infile("books1", :csv)) }

  let!(:model) do
    # Plain old ruby object for model, no guessable backend
    stub_const "Book", Class.new
  end

  describe "#import!" do
    context "when a backend cannot be guessed from the model" do
      let(:importer_class) do
        Class.new(Importu::Sources::CSV) do
          model "Book"
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
