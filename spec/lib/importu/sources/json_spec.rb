# frozen_string_literal: true
require "spec_helper"

require "importu/definition"
require "importu/sources/json"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::JSON do
  it_behaves_like "importer source", :json do
    subject(:source) { described_class.new(input, **source_config) }
    let(:definition) { Class.new(Importu::Definition) }
    let(:source_config) { definition.config[:sources][:json] }
  end

  describe "#initialize" do
    subject(:source) { described_class.new(StringIO.new(data), **source_config) }
    let(:definition) { Class.new(Importu::Definition) }
    let(:source_config) { definition.config[:sources][:json] }

    context "when document is JSON null" do
      let(:data) { "null" }
      it "raises InvalidInput with empty document message" do
        expect { source }.to raise_error(Importu::InvalidInput, "Empty document")
      end
    end
  end

end
