require "importu/config_dsl"
require "importu/converters"

class Importu::Definition
  extend Importu::ConfigDSL
  include Importu::Converters
end
