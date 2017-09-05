require "spec_helper"

require "importu/importer"
require "importu/sources/csv"

RSpec.describe "Dummy Backend" do
  let(:source) { Importu::Sources::CSV.new(infile("books1", :csv)) }
  subject(:importer) { importer_class.new(source) }

  let!(:model) do
    # Plain old ruby object for model, no guessable backend
    stub_const "Book", Class.new
  end

  describe "#import!" do
    context "when a backend cannot be guessed from the model" do
      let(:importer_class) do
        Class.new(Importu::Importer) do
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
