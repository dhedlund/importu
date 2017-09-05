# Using a module instead of a real importer class is a temporary workaround
# for sharing the importer definition. Importers currently have to inherit
# from a class representing their data source (i.e. *::CSV, *::JSON, etc).
# When that logic is made to be mixed in or configured via the DSL then this
# could be converted back into a class.

module BookImporterDefinition
  def self.included(base)
    base.class_eval do
      allow_actions :create, :update

      fields :title, :isbn10, :pages, :release_date, :authors

      field :pages, required: false, &convert_to(:integer)
      field :release_date, &convert_to(:date)

      field :authors, label: "author" do
        authors = clean(:authors).to_s.split(/(?:, )|(?: and )|(?: & )/i)
        raise ArgumentError, "at least one author is required" if authors.none?
        authors
      end

      field :by_matz, abstract: true do
        field_value(:authors).include?("Yukihiro Matsumoto")
      end
    end
  end
end
