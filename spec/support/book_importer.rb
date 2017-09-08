require "importu/importer"

module BookImporterDefinition
  def self.included(base)
    base.class_eval do
      allow_actions :create, :update

      fields :title, :isbn10, :pages, :release_date, :authors

      field :pages, required: false, &convert_to(:integer)
      field :release_date, &convert_to(:date)

      field :authors, label: "author" do
        authors = trimmed(:authors).to_s.split(/(?:, )|(?: and )|(?: & )/i)
        raise ArgumentError, "at least one author is required" if authors.none?
        authors
      end

      field :by_matz, abstract: true do
        field_value(:authors).include?("Yukihiro Matsumoto")
      end
    end
  end
end

class BookImporter < Importu::Importer
  include BookImporterDefinition
end
