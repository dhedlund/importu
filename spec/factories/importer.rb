FactoryGirl.define do
  factory :importer, :class => Importu::Importer do
    initialize_with do
      Importu::Importer.new(infile, options)
    end

    ignore do
      infile { StringIO.new }
      options { Hash.new }
    end
  end
end
