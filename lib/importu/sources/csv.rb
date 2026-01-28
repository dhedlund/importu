require "csv"
require "tempfile"

require "importu/exceptions"
require "importu/sources"

class Importu::Sources::CSV

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

  def rows
    @infile.rewind
    reader = ::CSV.new(@infile, **@csv_options)
    Enumerator.new do |yielder|
      reader.each {|row| yielder.yield(row.to_hash) unless row.header_row? }
    end
  end

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
