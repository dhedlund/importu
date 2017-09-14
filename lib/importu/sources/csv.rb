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
      @reader = ::CSV.new(@infile, @csv_options)
      @header = @reader.readline
    rescue CSV::MalformedCSVError => ex
      raise Importu::InvalidInput, ex.message
    end

    @data_pos = @infile.pos

    if @header.nil?
      raise Importu::InvalidInput, "Empty document"
    end
  end

  def rows
    @infile.pos = @data_pos
    Enumerator.new do |yielder|
      @reader.each {|row| yielder.yield(row.to_hash) }
    end
  end

  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    header = @header.fields | ["_errors"]
    itemized_errors = summary.itemized_errors

    Tempfile.new("import").tap do |file|
      writer = CSV.new(file, @csv_options)
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
