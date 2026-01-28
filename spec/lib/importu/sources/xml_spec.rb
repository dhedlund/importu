# frozen_string_literal: true

require "spec_helper"

require "importu/definition"
require "importu/sources/xml"

require_relative "importer_source_examples"

RSpec.describe Importu::Sources::XML do
  it_behaves_like "importer source", :xml do
    subject(:source) { described_class.new(input, **source_config) }
    let(:source_config) { definition.config[:sources][:xml] }

    let(:definition) do
      Class.new(Importu::Definition) { source :xml, records_xpath: "//book" }
    end
  end

  describe "xpath edge cases" do
    let(:xml_content) do
      <<~XML
        <?xml version="1.0"?>
        <library>
          <book><title>Red Dwarf</title></book>
          <book><title>Better Than Life</title></book>
        </library>
      XML
    end

    let(:input) { StringIO.new(xml_content) }

    context "when records_xpath matches nothing" do
      subject(:source) { described_class.new(input, records_xpath: "//nonexistent") }

      it "returns 0 rows" do
        expect(source.rows.count).to eq 0
      end
    end

    context "when records_xpath matches the root" do
      subject(:source) { described_class.new(input, records_xpath: "/library") }

      it "returns the root element as a single row" do
        rows = source.rows.to_a
        expect(rows.count).to eq 1
      end
    end

    context "when records_xpath uses attributes" do
      let(:xml_content) do
        <<~XML
          <?xml version="1.0"?>
          <library>
            <book isbn="123"><title>Red Dwarf</title></book>
            <book isbn="456"><title>Better Than Life</title></book>
          </library>
        XML
      end

      subject(:source) { described_class.new(input, records_xpath: "//book") }

      it "includes attributes in the row hash" do
        rows = source.rows.to_a
        expect(rows.first["isbn"]).to eq "123"
        expect(rows.first["title"]).to eq "Red Dwarf"
      end
    end
  end
end
