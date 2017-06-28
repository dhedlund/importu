FactoryGirl.define do
  factory :xml_importer, :class => Importu::Importer::Xml do
    initialize_with do
      Importu::Importer::Xml.new(infile, options)
    end

    transient do
      infile { StringIO.new("<r/>") }
      options { Hash.new }
    end
  end
end
