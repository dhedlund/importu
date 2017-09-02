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

  describe ".record_class" do
    it "returns Importu::Record by default" do
      expect(Importu::Importer.record_class).to eq Importu::Record
    end

    it "can be overridden globally" do
      orig = Importu::Importer.record_class
      begin
        custom_record_class = Class.new(Importu::Record)
        Importu::Importer.record_class custom_record_class
        expect(Importu::Importer.record_class).to eq custom_record_class

        klass = Class.new(Importu::Importer)
        expect(klass.record_class).to eq custom_record_class

      ensure
        Importu::Importer.record_class orig
      end
    end

    it "can be overridden in a subclass" do
      custom_record_class = Class.new(Importu::Record)
      klass = Class.new(Importu::Importer) do
        record_class custom_record_class
      end

      expect {
        expect(klass.record_class).to eq custom_record_class
      }.to_not change { Importu::Importer.record_class }
    end
  end
end
