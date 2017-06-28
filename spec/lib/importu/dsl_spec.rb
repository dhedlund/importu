require 'spec_helper'

describe Importu::Importer do
  describe "::record_class" do
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
