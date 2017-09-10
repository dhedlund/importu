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

  def rows
    Enumerator.new do |yielder|
      reader.xpath(@records_xpath).each do |xml|
        data = Hash[[
          *xml.attribute_nodes.map {|a| [a.node_name, a.content] },
          *xml.elements.map {|e| [e.name, e.content]},
        ]]
        yielder.yield(data)
      end
    end
  end

  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    @infile.rewind
    writer = Nokogiri::XML(@infile)
    writer.xpath("//_errors").remove

    itemized_errors = summary.itemized_errors
    writer.xpath(@records_xpath).each_with_index do |xml, index|
      if itemized_errors.key?(index)
        node = Nokogiri::XML::Node.new "_errors", writer
        node.content = itemized_errors[index].join(", ")
        xml.add_child(node)
      elsif only_errors
        xml.remove
      end
    end

    Tempfile.new("import").tap do |file|
      file.write(writer)
      file.rewind
    end
  end

  private def reader
    @reader ||= Nokogiri::XML(@infile)
  end

end
