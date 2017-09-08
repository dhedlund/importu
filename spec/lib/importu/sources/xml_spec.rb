require "spec_helper"

require "importu/importer"
require "importu/sources/xml"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::XML do
  it_behaves_like "importer source", :xml do
    subject(:source) { described_class.new(input, importer_class.config) }
    let(:importer_class) { Class.new(Importu::Importer) { records_xpath "//book" } }
  end
end
