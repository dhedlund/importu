require "multi_json"
require "tempfile"

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

  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    itemized_errors = summary.itemized_errors
    updated_rows = rows.each.with_index.with_object([]) do |(row,index), acc|
      if itemized_errors.key?(index)
        acc << row.merge("_errors" => itemized_errors[index].join(", "))
      elsif only_errors
        # Requested to only include rows with new errors, row has none
      elsif row.key?("_errors")
        acc << row.dup.tap {|r| r.delete("_errors") }
      else
        acc << row
      end
    end

    Tempfile.new("import").tap do |file|
      file.write(JSON.pretty_generate(updated_rows))
      file.rewind
    end
  end

end
