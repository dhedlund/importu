require "nokogiri"

class Importu::Importer::Xml < Importu::Importer
  config_dsl :records_xpath

  def initialize(infile, xml_options: {}, **options)
    super(infile, options)

    if reader.root.nil?
      raise Importu::InvalidInput, "Empty document"
    elsif reader.errors.any?
      raise Importu::InvalidInput, reader.errors.join("\n")
    end
  end

  def reader
    @reader ||= Nokogiri::XML(infile)
  end

  def import!(&block)
    reader.xpath("//_errors").remove
    result = super
    outfile.write(reader) if @invalid > 0
    result
  end

  def records
    Enumerator.new do |yielder|
      reader.xpath(records_xpath).each do |xml|
        data = Hash[xml.elements.map {|e| [e.name, e.content]}]
        yielder.yield record_class.new(self.definition, data, xml)
      end
    end
  end

  def import_record(record, &block)
    begin
      super
      record.raw_data.remove
    rescue Importu::InvalidRecord => e
      add_xml_record_error(record.raw_data, e.message)
    end
  end

  private def add_xml_record_error(xml, text)
    unless node = xml.xpath("./_errors").first
      node = Nokogiri::XML::Node.new "_errors", reader
      xml.add_child(node)
    end
    node.content = text + ","
  end

end
