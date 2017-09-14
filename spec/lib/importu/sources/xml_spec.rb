require "spec_helper"

require "importu/importer"
require "importu/sources/xml"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::XML do
  it_behaves_like "importer source", :xml do
    subject(:source) { described_class.new(input, source_config) }
    let(:source_config) { importer_class.config[:sources][:xml] }

    let(:importer_class) do
      Class.new(Importu::Importer) { source :xml, records_xpath: "//book" }
    end
  end
end
