require "spec_helper"

RSpec.describe Importu::Importer::Csv do
  subject(:importer) { importer_class.new(StringIO.new(data)) }

  class PoroBook
    # Plain old ruby object, no guessable backend
  end

  let(:importer_class) do
    Class.new(described_class) do
      model "PoroBook"
      backend :dummy
      fields :title, :author, :isbn10, :pages, :release_date
    end
  end

  let(:data) do
    <<-DATA.gsub(/^\s+/, "")
      "isbn10","title","author","release_date","pages"
      "0596516177","The Ruby Programming Language","David Flanagan and Yukihiro Matsumoto","Feb 1, 2008","448"
      "1449355978","Computer Science Programming Basics in Ruby","Ophir Frieder, Gideon Frieder and David Grossman","May 1, 2013","188"
      "0596523696","Ruby Cookbook"," Lucas Carlson and Leonard Richardson","Jul 26, 2006","910"
    DATA
  end

  describe "#initialize" do
    context "with custom csv options" do
      let(:csv_options) { { skip_blanks: false } }
      let(:data) { super() + "\n\n\n" }

      it "allows overriding csv options" do
        custom_importer = importer_class.new(StringIO.new(data), csv_options: csv_options)
        expect(custom_importer.records.count).to be > importer.records.count
      end
    end

    context "when input file is blank" do
      let(:data) { "" }

      it "raises an InvalidInput exception" do
        expect { importer }.to raise_error(Importu::InvalidInput)
      end
    end
  end

  describe "#records" do
    it "returns records parsed from source data" do
      expect(importer.records.count).to eq 3
    end

    context "when input has header but no records" do
      let(:data) { %("isbn10","title","author","release_date","pages") }

      it "treats file as having no records" do
        expect(importer.records.count).to eq 0
      end
    end

    it "returns same records on subsequent invocations" do
      expect(importer.records.count).to eq importer.records.count
    end
  end

  describe "#import!" do
    it "tries to import each record" do
      importer.import!
      expect(importer.created).to eq 3
      expect(importer.total).to eq 3
    end

    context "when a backend cannot be guessed from the model" do
      let(:importer_class) do
        Class.new(described_class) do
          model "PoroBook"
          fields :title, :author, :isbn10, :pages, :release_date
        end
      end

      it "raises an error" do
        importer # Ensure exception doesn't happen at initialization
        expect { importer.import! }.to raise_error(Importu::BackendMatchError)
      end
    end
  end

end
