FactoryGirl.define do
  factory :importer_record, :class => Importu::Record do
    initialize_with do
      Importu::Record.new(importer, data, raw_data)
    end

    ignore do
      importer { build(:importer) }
      data { Hash.new }
      raw_data { Hash.new }
    end
  end
end
