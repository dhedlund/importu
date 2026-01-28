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
# @example With options
#   source = Importu::Sources::CSV.new("data.csv", csv_options: { col_sep: ";" })
#
# @api public
class Importu::Sources::CSV
  # Creates a new CSV source.
  #
  # @param infile [String, IO] file path or IO object to read from
  # @param csv_options [Hash] options passed to Ruby's CSV parser
  # @raise [Importu::InvalidInput] if the CSV is malformed or empty
  def initialize(infile, csv_options: {}, **)
    @infile = infile.respond_to?(:readline) ? infile : File.open(infile, "rb")

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
