# frozen_string_literal: true
require "csv"
require "tempfile"

require "importu/exceptions"
require "importu/sources"

# Parses CSV files as import source data.
#
# Each row becomes a hash with header names as keys. The CSV must have a
# header row.
#
# @example Basic usage
#   source = Importu::Sources::CSV.new("data.csv")
#   source.rows.each { |row| puts row["name"] }
#
# @example From a string
#   csv_data = "name,email\nAlice,alice@example.com"
#   source = Importu::Sources::CSV.new(StringIO.new(csv_data))
#
# @example With semicolon delimiter
#   source = Importu::Sources::CSV.new("data.csv", csv_options: { col_sep: ";" })
#
# @example With tab delimiter
#   source = Importu::Sources::CSV.new("data.tsv", csv_options: { col_sep: "\t" })
#
# @example Common csv_options
#   csv_options: {
#     col_sep: ";",        # Column separator (default: ",")
#     quote_char: "'",     # Quote character (default: '"')
#     encoding: "UTF-8",   # File encoding
#   }
#
# @see https://ruby-doc.org/stdlib/libdoc/csv/rdoc/CSV.html Ruby CSV documentation
# @api public
class Importu::Sources::CSV
  # Creates a new CSV source.
  #
  # @param infile [String, IO] file path or IO object to read from
  # @param csv_options [Hash] options passed to Ruby's CSV parser
  # @raise [Importu::InvalidInput] if the CSV is malformed or empty
  def initialize(infile, csv_options: {}, **)
    @owns_handle = !infile.respond_to?(:readline)
    @infile = @owns_handle ? File.open(infile, "rb") : infile

    @csv_options = {
      headers:        true,
      return_headers: true,
      write_headers:  true,
      skip_blanks:    true,
    }.merge(csv_options)

    begin
      @reader = ::CSV.new(@infile, **@csv_options)
      @header = @reader.readline
    rescue CSV::MalformedCSVError => e
      raise Importu::InvalidInput, e.message
    end

    if @header.nil?
      raise Importu::InvalidInput, "Empty document"
    end
  rescue StandardError
    close
    raise
  end

  # Closes the underlying file handle if opened by this source.
  #
  # Safe to call multiple times. Only closes handles that were opened
  # by this source (not IO objects passed in).
  #
  # @return [void]
  def close
    return unless @owns_handle && @infile && !@infile.closed?
    @infile.close
  end

  # Returns an enumerator that yields each row as a hash.
  #
  # @return [Enumerator<Hash>] rows with header names as keys
  def rows
    @infile.rewind
    reader = ::CSV.new(@infile, **@csv_options)
    Enumerator.new do |yielder|
      reader.each {|row| yielder.yield(row.to_hash) unless row.header_row? }
    end
  end

  # Generates a CSV file with error information appended.
  #
  # Creates a copy of the original data with an "_errors" column containing
  # any validation errors for each row. Useful for returning to data providers.
  #
  # @param summary [Importu::Summary] the import summary containing errors
  # @param only_errors [Boolean] if true, only include rows that had errors
  # @return [Tempfile, nil] temp file with error data, or nil if no errors
  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    header = @header.fields | ["_errors"]
    itemized_errors = summary.itemized_errors

    Tempfile.new("import").tap do |file|
      writer = CSV.new(file, **@csv_options)
      writer << header

      rows.each.with_index do |row, index|
        errors = itemized_errors.key?(index) \
          ? itemized_errors[index].join(", ")
          : nil

        if errors || !only_errors
          writer << row.merge("_errors" => errors).values_at(*header)
        end
      end

      file.rewind
    end
  end

end
