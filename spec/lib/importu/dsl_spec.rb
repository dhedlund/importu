require 'spec_helper'

RSpec.describe Importu::Importer do
  describe ".model" do
    let(:importer) { Class.new(Importu::Importer) }

    class MyModelLOL; end

    it "returns nil if unset" do
      expect(importer.model).to be_nil
    end

    it "allows setting model to a class" do
      importer.model MyModelLOL
      expect(importer.model).to eq MyModelLOL
    end

    it "allows setting model to stringified class name" do
      expect { importer.model "MyModelLOL" }
        .to change { importer.model }.to(MyModelLOL)
    end

    it "lazily evaulates model name until requested" do
      importer.model "MyModelWow"
      expect { importer.model }.to raise_error(NameError)
      class MyModelWow; end
      expect(importer.model).to be MyModelWow
    end
  end

  describe ".record_class" do
    it "returns Importu::Record by default" do
      expect(Importu::Importer.record_class).to eq Importu::Record
    end

    it "can be overridden globally" do
      custom_record_class = Class.new(Importu::Record)
      orig = Importu::Importer.record_class
      Importu::Importer.record_class custom_record_class
      expect(Importu::Importer.record_class).to eq custom_record_class
      Importu::Importer.record_class orig
    end

    it "can be overridden in a subclass" do
      custom_record_class = Class.new(Importu::Record)
      klass = Class.new(Importu::Importer) do
        record_class custom_record_class
      end

      expect(klass.record_class).to eq custom_record_class
    end
  end
end
