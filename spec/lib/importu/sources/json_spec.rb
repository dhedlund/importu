require "spec_helper"

require "importu/importer"
require "importu/sources/json"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::JSON do
  it_behaves_like "importer source", :json do
    subject(:source) { described_class.new(input, source_config) }
    let(:importer_class) { Class.new(Importu::Importer) }
    let(:source_config) { importer_class.config[:sources][:json] }
  end

  describe "#initialize" do
    subject(:source) { described_class.new(StringIO.new(data), source_config) }
    let(:importer_class) { Class.new(Importu::Importer) }
    let(:source_config) { importer_class.config[:sources][:json] }

    context "when root element is not an array" do
      %w({}, "foo", 3, 3.7, false, nil).each do |bad_data|
        context "when root is #{bad_data}" do
          let(:data) { bad_data }
          it "raises InvalidInput exception" do
            expect { source }.to raise_error(Importu::InvalidInput)
          end
        end
      end
    end
  end

end
