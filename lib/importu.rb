# frozen_string_literal: true

# Importu is a Ruby gem for declarative data import.
#
# Define importers as readable contracts with fields, converters, and rules.
# The gem handles parsing, converting, finding/creating records, and reporting.
#
# @example Basic usage
#   class BookImporter < Importu::Importer
#     fields :title, :author, :isbn
#   end
#
#   source = Importu::Sources::CSV.new("books.csv")
#   importer = BookImporter.new(source)
#   importer.records.each { |record| puts record[:title] }
#
# @api public
module Importu; end

require "importu/importer"

require "importu/sources/csv"
require "importu/sources/json"
require "importu/sources/xml"

require "importu/backends/active_record" if defined?(::ActiveRecord)
