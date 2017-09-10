require "spec_helper"

require "importu/importer"
require "importu/sources/xml"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::XML do
  it_behaves_like "importer source", :xml do
    subject(:source) { described_class.new(input, source_config) }
    let(:importer_class) { Class.new(Importu::Importer) { records_xpath "//book" } }
    let(:source_config) { importer_class.config[:sources][:xml] }
  end
end
