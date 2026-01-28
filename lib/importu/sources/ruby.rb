# frozen_string_literal: true
require "importu/sources"

# Uses Ruby objects as import source data.
#
# Accepts an array of hashes or any enumerable that yields objects responding
# to #to_hash. Hash keys should be strings to match other source formats.
#
# @example Basic usage
#   data = [{ "name" => "Alice" }, { "name" => "Bob" }]
#   source = Importu::Sources::Ruby.new(data)
#   source.rows.each { |row| puts row["name"] }
#
# @api public
class Importu::Sources::Ruby
  # Creates a new Ruby source.
  #
  # @param data [Array<Hash>, Enumerable] objects that respond to #to_hash
  def initialize(data, **)
    @data = data
  end

  # Returns an enumerator that yields each element as a hash.
  #
  # @return [Enumerator<Hash>] rows from the data array
  def rows
    Enumerator.new do |yielder|
      @data.each {|row| yielder.yield(row.to_hash) }
    end
  end

  # Not implemented for Ruby source.
  #
  # @param summary [Importu::Summary] the import summary (unused)
  # @param only_errors [Boolean] (unused)
  # @return [nil] always returns nil
  def write_errors(summary, only_errors: false); end

  # No-op for Ruby source (no file handles to close).
  #
  # Provided for API consistency with file-based sources.
  #
  # @return [void]
  def close; end

end
