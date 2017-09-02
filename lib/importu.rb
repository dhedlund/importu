module Importu; end

require "importu/importer/csv"
require "importu/importer/json"
require "importu/importer/xml"

require "importu/backends/active_record" if defined?(::ActiveRecord)
