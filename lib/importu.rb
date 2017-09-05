module Importu; end

require "importu/sources/csv"
require "importu/sources/json"
require "importu/sources/xml"

require "importu/backends/active_record" if defined?(::ActiveRecord)
