require "nokogiri"

require "importu/exceptions"
require "importu/sources"

class Importu::Sources::XML
  def initialize(infile, records_xpath:, xml_options: {}, **)
    @infile = infile.respond_to?(:readline) ? infile : File.open(infile, "rb")
    @records_xpath = records_xpath

    if reader.root.nil?
      raise Importu::InvalidInput, "Empty document"
    elsif reader.errors.any?
      raise Importu::InvalidInput, reader.errors.join("\n")
    end
  end

  def outfile
    return nil unless @has_errors

    @outfile ||= Tempfile.new("import").tap do |file|
      file.write(reader)
    end
  end

  def rows
    Enumerator.new do |yielder|
      reader.xpath(@records_xpath).each do |xml|
        data = Hash[[
          *xml.attribute_nodes.map {|a| [a.node_name, a.content] },
          *xml.elements.map {|e| [e.name, e.content]},
        ]]
        yielder.yield(data, xml)
      end
    end
  end

  def wrap_import_record(record, &block)
    begin
      yield
      record.raw_data.remove
    rescue Importu::InvalidRecord => e
      add_xml_record_error(record.raw_data, e.message)
    end
  end

  private def add_xml_record_error(xml, text)
    unless @has_errors
      # Writing first error from import run, make sure there are no errors
      # from previous runs still hanging out in the file.
      reader.xpath("//_errors").remove
    end

    unless node = xml.xpath("./_errors").first
      node = Nokogiri::XML::Node.new "_errors", reader
      xml.add_child(node)
    end
    node.content = text + ","

    @has_errors = true
  end

  private def reader
    @reader ||= Nokogiri::XML(@infile)
  end

end
