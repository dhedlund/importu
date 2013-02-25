require 'spec_helper'

describe Importu::Importer::Json do
  subject(:importer) { build(:json_importer, :data => data) }

  context "input file is blank" do
    let(:data) { "" }

    it "raises an InvalidInput exception" do
      expect { importer }.to raise_error Importu::InvalidInput
    end
  end

  context "non-array root elements" do
    %w({}, "foo", 3, 3.7, false, nil).each do |data|
      it "raises InvalidInput exception if root is #{data}" do
        expect { build(:json_importer, :data => "") }.to raise_error Importu::InvalidInput
      end
    end
  end

  context "input file is []" do
    let(:data) { "[]" }

    it "treats file as having 0 records" do
      importer.records.should have(0).items
    end
  end

  context "input file is [{},{}]" do
    let(:data) { "[{},{}]" }

    it "treats file as having 2 records" do
      importer.records.should have(2).items
    end
  end
end
