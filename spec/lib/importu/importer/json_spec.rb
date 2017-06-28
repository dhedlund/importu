require 'spec_helper'

RSpec.describe Importu::Importer::Json do
  let(:data) { nil } # string version of input file
  subject(:importer) { Importu::Importer::Json.new(StringIO.new(data)) }

  context "input file is blank" do
    let(:data) { "" }

    it "raises an InvalidInput exception" do
      expect { importer }.to raise_error(Importu::InvalidInput)
    end
  end

  context "non-array root elements" do
    %w({}, "foo", 3, 3.7, false, nil).each do |bad_data|
      context "when root is #{bad_data}" do
        let(:data) { bad_data }
        it "raises InvalidInput exception" do
          expect { importer }.to raise_error(Importu::InvalidInput)
        end
      end
    end
  end

  context "input file is []" do
    let(:data) { "[]" }

    it "treats file as having 0 records" do
      expect(importer.records.count).to eq 0
    end
  end

  context "input file is [{},{}]" do
    let(:data) { "[{},{}]" }

    it "treats file as having 2 records" do
      expect(importer.records.count).to eq 2
    end
  end
end
