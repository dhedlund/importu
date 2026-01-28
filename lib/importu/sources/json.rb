# frozen_string_literal: true
require "json"
require "tempfile"

require "importu/exceptions"
require "importu/sources"

# Parses JSON files as import source data.
#
# The JSON must have an array as the root element. Each array element becomes
# a row. The entire file is loaded into memory.
#
# @example Basic usage
#   source = Importu::Sources::JSON.new("data.json")
#   source.rows.each { |row| puts row["name"] }
#
# @example Expected JSON format
#   # data.json
#   [
#     { "name": "Alice", "email": "alice@example.com" },
#     { "name": "Bob", "email": "bob@example.com" }
#   ]
#
# @example From a string
#   json_data = '[{"name": "Alice"}, {"name": "Bob"}]'
#   source = Importu::Sources::JSON.new(StringIO.new(json_data))
#
# @note The entire JSON file is loaded into memory. For very large files,
#   consider using CSV or a streaming JSON parser.
#
# @api public
class Importu::Sources::JSON
  # Creates a new JSON source.
  #
  # @param infile [String, IO] file path or IO object to read from
  # @raise [Importu::InvalidInput] if the JSON is malformed or empty
  def initialize(infile, **)
    owns_handle = !infile.respond_to?(:readline)
    @infile = owns_handle ? File.open(infile, "rb") : infile

    begin
      @infile.rewind
      @reader = ::JSON.parse(@infile.read)
    rescue ::JSON::ParserError => e
      raise Importu::InvalidInput, e.message
    ensure
      # JSON loads entire content into memory, so we can close immediately
      @infile.close if owns_handle && @infile && !@infile.closed?
    end

    if @reader.nil?
      raise Importu::InvalidInput, "Empty document"
    end
  end

  # Closes any resources held by this source.
  #
  # For JSON sources, the file is already closed after initialization
  # since the entire content is loaded into memory. This method is
  # provided for API consistency with other sources.
  #
  # @return [void]
  def close
    # JSON source closes file immediately after reading into memory
  end

  # Returns an enumerator that yields each element as a hash.
  #
  # @return [Enumerator<Hash>] rows from the JSON array
  def rows
    Enumerator.new do |yielder|
      @reader.each {|row| yielder.yield(row) }
    end
  end

  # Generates a JSON file with error information appended.
  #
  # Creates a copy of the original data with an "_errors" key containing
  # any validation errors for each row.
  #
  # @param summary [Importu::Summary] the import summary containing errors
  # @param only_errors [Boolean] if true, only include rows that had errors
  # @return [Tempfile, nil] temp file with error data, or nil if no errors
  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    itemized_errors = summary.itemized_errors
    updated_rows = rows.each.with_index.with_object([]) do |(row, index), acc|
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
