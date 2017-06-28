FactoryGirl.define do
  factory :json_importer, :class => Importu::Importer::Json do
    initialize_with do
      infile = StringIO.new(data) if data
      Importu::Importer::Json.new(infile, options)
    end

    transient do
      data nil # string version of input file
      infile { StringIO.new("[]") }
      options { Hash.new }
    end
  end
end
