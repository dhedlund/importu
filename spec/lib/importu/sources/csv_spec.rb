require "spec_helper"

require "importu/importer"
require "importu/sources/csv"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::CSV do
  it_behaves_like "importer source", :csv do
    subject(:source) { described_class.new(input, importer_class.config) }
    let(:importer_class) { Class.new(Importu::Importer) }
  end

  describe "#initialize" do
    context "with custom csv options" do
      let(:csv_options) { { skip_blanks: false } }
      let(:data) { "foo\n\n\n" }

      it "allows overriding csv options" do
        original_source = described_class.new(StringIO.new(data))
        source = described_class.new(StringIO.new(data), csv_options: csv_options)
        expect(source.rows.count).to be > original_source.rows.count
      end
    end
  end

end
