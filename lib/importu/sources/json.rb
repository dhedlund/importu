require "multi_json"

require "importu/exceptions"
require "importu/sources"

class Importu::Sources::JSON
  def initialize(infile, **)
    @infile = infile.respond_to?(:readline) ? infile : File.open(infile, "rb")

    begin
      @infile.rewind
      @reader = MultiJson.load(@infile.read)
    rescue MultiJson::DecodeError => e
      raise Importu::InvalidInput, e.message
    end
  end

  def rows
    Enumerator.new do |yielder|
      @reader.each {|row| yielder.yield(row) }
    end
  end

  def write_errors(summary)
    return unless summary.itemized_errors.any?

    itemized_errors = summary.itemized_errors
    updated_rows = rows.map.with_index do |row, index|
      if itemized_errors.key?(index)
        row.merge("_errors" => itemized_errors[index].join(", "))
      elsif row.key?("_errors")
        row.dup.tap {|r| r.delete("_errors") }
      else
        row
      end
    end

    Tempfile.new("import").tap do |file|
      file.write(JSON.pretty_generate(updated_rows))
      file.rewind
    end
  end

end
