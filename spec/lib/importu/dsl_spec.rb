require "spec_helper"

require "importu/importer"

RSpec.describe Importu::Importer do
  describe ".model" do
    let(:importer) { Class.new(Importu::Importer) }

    it "returns nil if unset" do
      expect(importer.model).to be_nil
    end

    it "allows setting model to a class" do
      model = Class.new
      importer.model model
      expect(importer.model).to eq model
    end

    it "allows setting model to stringified class name" do
      stub_const "MyModelLOL", Class.new
      expect { importer.model "MyModelLOL" }
        .to change { importer.model }.to(MyModelLOL)
    end

    it "lazily evaulates model name until requested" do
      importer.model "MyModelWow"
      expect { importer.model }.to raise_error(NameError)
      stub_const "MyModelWow", Class.new
      expect(importer.model).to be MyModelWow
    end
  end

end
