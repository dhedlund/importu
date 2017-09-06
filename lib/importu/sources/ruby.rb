require "importu/record"
require "importu/sources"

# Supports a plain array of hashes as source data, or an enumerable that
# produces objects that respond to #to_hash. Hash keys must be strings.
class Importu::Sources::Ruby

  def initialize(data)
    @data = data
  end

  def outfile
  end

  def records(definition)
    Enumerator.new do |yielder|
      @data.each do |row|
        yielder.yield Importu::Record.new(definition, row.to_hash, row)
      end
    end
  end

  def wrap_import_record(record, &block)
    yield
  end

end
