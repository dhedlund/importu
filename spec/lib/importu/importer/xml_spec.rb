require 'spec_helper'

describe Importu::Importer::Xml do
  subject(:importer) { build(:xml_importer, :infile => infile) }

  context "input file is blank" do
    let(:infile) { StringIO.new }

    it "raises an InvalidInput exception" do
      expect { importer }.to raise_error Importu::InvalidInput
    end
  end

end
