require "multi_json"

require "importu/exceptions"
require "importu/record"
require "importu/sources"

class Importu::Sources::JSON
  def initialize(infile)
    @infile = infile.respond_to?(:readline) ? infile : File.open(infile, "rb")

    begin
      infile.rewind
      @reader = MultiJson.load(infile.read)
    rescue MultiJson::DecodeError => e
      raise Importu::InvalidInput, e.message
    end
  end

  def outfile
    return nil unless @error_records

    @outfile ||= Tempfile.new("import").tap do |outfile|
      outfile.write(JSON.pretty_generate(@error_records))
    end
  end

  def records(definition)
    Enumerator.new do |yielder|
      @reader.each_with_index do |data,idx|
        yielder.yield Importu::Record.new(definition, data, data)
      end
    end
  end

  def wrap_import_record(record, &block)
    begin
      yield
    rescue Importu::InvalidRecord => e
      write_error(record.raw_data, e.message)
    end
  end

  private def write_error(data, msg)
    @error_records ||= []
    @error_records << data.merge("_errors" => msg)
  end

end
