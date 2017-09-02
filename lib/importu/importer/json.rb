require "multi_json"

require "importu/importer"
require "importu/exceptions"

class Importu::Importer::Json < Importu::Importer
  def initialize(infile, **options)
    super(infile, options)

    begin
      infile.rewind
      @reader = MultiJson.load(infile.read)
    rescue MultiJson::DecodeError => e
      raise Importu::InvalidInput, e.message
    end
  end

  def import!(&block)
    result = super
    outfile.write(JSON.pretty_generate(@error_records)) if @invalid > 0
    result
  end

  def records(&block)
    Enumerator.new do |yielder|
      @reader.each_with_index do |data,idx|
        yielder.yield record_class.new(self.definition, data, data)
      end
    end
  end

  def import_record(record, &block)
    begin
      super
    rescue Importu::InvalidRecord => e
      write_error(record.raw_data, e.message)
    end
  end

  private def write_error(data, msg)
    @error_records ||= []
    @error_records << data.merge("_errors" => msg)
  end

end
