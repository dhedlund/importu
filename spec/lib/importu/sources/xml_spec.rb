require "spec_helper"

require "importu/definition"
require "importu/sources/xml"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::XML do
  it_behaves_like "importer source", :xml do
    subject(:source) { described_class.new(input, source_config) }
    let(:source_config) { definition.config[:sources][:xml] }

    let(:definition) do
      Class.new(Importu::Definition) { source :xml, records_xpath: "//book" }
    end
  end
end
