# frozen_string_literal: true
require "nokogiri"
require "tempfile"

require "importu/exceptions"
require "importu/sources"

# Parses XML files as import source data.
#
# Requires an XPath expression to identify which elements represent records.
# Each matching element becomes a row, with child elements and attributes
# as fields.
#
# ## Field Extraction
# For each matching element:
# - XML attributes become fields (e.g., `<book id="123">` → `{ "id" => "123" }`)
# - Child element text becomes fields (e.g., `<title>Ruby</title>` → `{ "title" => "Ruby" }`)
#
# @example Basic usage
#   source = Importu::Sources::XML.new("data.xml", records_xpath: "//book")
#   source.rows.each { |row| puts row["title"] }
#
# @example Expected XML format
#   # data.xml
#   <library>
#     <book id="1">
#       <title>The Ruby Way</title>
#       <author>Hal Fulton</author>
#     </book>
#     <book id="2">
#       <title>Programming Ruby</title>
#       <author>Dave Thomas</author>
#     </book>
#   </library>
#
# @example Resulting rows
#   # With records_xpath: "//book"
#   { "id" => "1", "title" => "The Ruby Way", "author" => "Hal Fulton" }
#   { "id" => "2", "title" => "Programming Ruby", "author" => "Dave Thomas" }
#
# @example Configure in importer
#   class BookImporter < Importu::Importer
#     source :xml, records_xpath: "//book"
#   end
#
# @note Requires the nokogiri gem.
# @api public
class Importu::Sources::XML
  # Creates a new XML source.
  #
  # @param infile [String, IO] file path or IO object to read from
  # @param records_xpath [String] XPath expression to select record elements
  # @param xml_options [Hash] options passed to Nokogiri (currently unused)
  # @raise [Importu::InvalidInput] if the XML is malformed or empty
  def initialize(infile, records_xpath:, xml_options: {}, **)
    @owns_handle = !infile.respond_to?(:readline)
    @infile = @owns_handle ? File.open(infile, "rb") : infile
    @records_xpath = records_xpath

    if reader.root.nil?
      raise Importu::InvalidInput, "Empty document"
    elsif reader.errors.any?
      raise Importu::InvalidInput, reader.errors.join("\n")
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

  # Returns an enumerator that yields each matching element as a hash.
  #
  # Element attributes and child element text content become hash keys.
  #
  # @return [Enumerator<Hash>] rows from matching XML elements
  def rows
    Enumerator.new do |yielder|
      reader.xpath(@records_xpath).each do |xml|
        data = [
          *xml.attribute_nodes.map {|a| [a.node_name, a.content] },
          *xml.elements.map {|e| [e.name, e.content]},
        ].to_h
        yielder.yield(data)
      end
    end
  end

  # Generates an XML file with error information appended.
  #
  # Creates a copy of the original data with an "_errors" child element
  # containing any validation errors for each record.
  #
  # @param summary [Importu::Summary] the import summary containing errors
  # @param only_errors [Boolean] if true, only include records that had errors
  # @return [Tempfile, nil] temp file with error data, or nil if no errors
  def write_errors(summary, only_errors: false)
    return unless summary.itemized_errors.any?

    @infile.rewind
    writer = Nokogiri::XML(@infile) { |config| config.nonet }
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
    @reader ||= Nokogiri::XML(@infile) { |config| config.nonet }
  end

end
