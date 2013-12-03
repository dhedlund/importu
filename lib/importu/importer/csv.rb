require 'csv'

class Importu::Importer::Csv < Importu::Importer
  def initialize(infile, options = {})
    super

    @csv_options = {
      :headers        => true,
      :return_headers => true,
      :write_headers  => true,
      :skip_blanks    => true,
    }.merge(options[:csv_options]||{})

    @reader = ::CSV.new(@infile, @csv_options)
    @header = @reader.readline
    @data_pos = @infile.pos
  end

  def records
    @infile.pos = @data_pos
    Enumerator.new do |yielder|
      @reader.each do |row|
        yielder.yield record_class.new(self, row.to_hash, row)
      end
    end
  end

  def import_record(record, finder_scope, &block)
    begin
      super
    rescue Importu::MissingField => e
      # if one record missing field, all are, major error
      raise Importu::InvalidInput, "missing required field: #{e.message}"
    rescue Importu::InvalidRecord => e
      write_error(record.raw_data, e.message)
    end
  end


  private

  def write_error(data, msg)
    unless @writer
      @writer = ::CSV.new(outfile, @csv_options)
      @header['_errors'] = '_errors'
      @writer << @header
    end

    data['_errors'] = msg
    @writer << data
  end
end
