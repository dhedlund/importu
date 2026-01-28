# frozen_string_literal: true
require "importu/config_dsl"
require "importu/converters"

# Base class for import definitions.
#
# Definition provides the DSL for declaring fields, converters, and import
# configuration. Extend this class to create reusable field definitions that
# can be shared across multiple importers.
#
# @example Creating a reusable definition
#   class BookFields < Importu::Definition
#     fields :title, :author
#     field :isbn, &convert_to(:string)
#   end
#
# @see Importu::Importer
# @see Importu::ConfigDSL
# @api public
class Importu::Definition
  extend Importu::ConfigDSL
  include Importu::Converters
end
