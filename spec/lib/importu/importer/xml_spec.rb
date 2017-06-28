require 'spec_helper'

RSpec.describe Importu::Importer::Xml do
  let(:data) { nil } # string version of input file
  subject(:importer) { Importu::Importer::Xml.new(StringIO.new(data)) }

  context "input file is blank" do
    let(:data) { "" }

    it "raises an InvalidInput exception" do
      expect { importer }.to raise_error Importu::InvalidInput
    end
  end

end
