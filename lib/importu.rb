# frozen_string_literal: true

# Importu is a Ruby gem for declarative data import.
#
# Define importers as readable contracts with fields, converters, and rules.
# The gem handles parsing, converting, finding/creating records, and reporting.
#
# ## Quick Start
#
#     require "importu"
#
#     class BookImporter < Importu::Importer
#       fields :title, :author, :isbn
#     end
#
#     source = Importu::Sources::CSV.new("books.csv")
#     importer = BookImporter.new(source)
#     importer.records.each { |record| puts record[:title] }
#
# ## Key Classes
#
# - {Importu::Importer} - Base class for defining importers
# - {Importu::Sources::CSV} - Parse CSV files
# - {Importu::Sources::JSON} - Parse JSON files
# - {Importu::Sources::XML} - Parse XML files
# - {Importu::Summary} - Import results and error reporting
# - {Importu::Record} - Individual record from source data
#
# ## DSL Reference
#
# See {Importu::ConfigDSL} for all importer configuration options:
# fields, converters, model, find_by, allow_actions, and more.
#
# ## Built-in Converters
#
# See {Importu::Converters} for type conversion: boolean, date, datetime,
# decimal, float, integer, string, trimmed.
#
# @api public
module Importu; end

require "importu/importer"

require "importu/sources/csv"
require "importu/sources/json"
require "importu/sources/xml"

require "importu/backends/active_record" if defined?(::ActiveRecord)
