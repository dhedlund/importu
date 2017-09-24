# Records and aggregates results from an import. Each time the importer
# finishes processing a record, it makes a call back to the summarizer
# to record the progress made so far. That may be successfully creating
# or updating a record, or recording the fact that something went wrong
# during the attempt.
class Importu::Summary

  # The number of times a :created result was recorded
  #
  # @example
  #   summary.created # => 2
  #
  # @return [Integer]
  #
  # @api public
  attr_reader :created

  # The number of times an :invalid result was recorded
  #
  # @example
  #   summary.invalid # => 3
  #
  # @return [Integer]
  #
  # @api public
  attr_reader :invalid

  # A hash of record indexes and the errors recorded for that record
  #
  # @example
  #   summary.itemized_errors
  #
  #   {
  #     0 => [
  #       #<Importu::InvalidRecord: ...>,
  #       #<Importu::InvalidRecord: ...>,
  #     ],
  #     3 => [
  #       #<Importu::InvalidRecord: ...>
  #     ]
  #   }
  #
  # @return [Hash<Integer=>Array>] a hash of record indexes and the errors
  #   recorded for that record. Each key represents the position of the
  #   record in the source data and the value is a list of errors.
  #   Errors will all be Importu::InvalidRecord exceptions or subclasses
  #   that can be converted to a string using #to_s.
  #
  # @api public
  attr_reader :itemized_errors

  # The total number of times any result was recorded
  #
  # @example
  #   summary.total # => 36
  #
  # @return [Integer]
  #
  # @api public
  attr_reader :total

  # The number of times an :unchanged result was recorded
  #
  # @example
  #   summary.unchanged # => 30
  #
  # @return [Integer]
  #
  # @api public
  attr_reader :unchanged

  # The number of times an :updated result was recorded
  #
  # @example
  #   summary.updated # => 1
  #
  # @return [Integer]
  #
  # @api public
  attr_reader :updated

  # A hash of error messages and the number of occurrences of each
  #
  # @example
  #   summary.validation_errors
  #
  #   {
  #     "description is required" => 3,
  #     "title is too long" => 2
  #   }
  #
  # @return [Hash<String=>Integer>] a hash of error messages, with each key
  #   being an error message and the value representing the number of times
  #   the error was recorded.
  #
  # @api public
  attr_reader :validation_errors

  # Creates a new instance of a summary. Generally, a new summary object
  # would get created on each attempt to import data.
  #
  # @example
  #   Summary.new # => Importu::Summary.new
  #
  # @api semipublic
  def initialize
    @total = @invalid = @created = @updated = @unchanged = 0
    @validation_errors = Hash.new(0) # counter for each validation error

    # Sparse array of error messages grouped by the index of the record.
    # Should stay ordered by index because rows are processed sequentially
    # and hashes preserve insertion order. Recorded errors without an index
    # will be ignored. Index is 0-based from first record.
    @itemized_errors = Hash.new {|h,idx| h[idx] = [] }
  end

  # Record the result of an import. The result may be used for aggregated
  # statistics or, in the case of errors, a way to retrieve error messages
  # associated with a record after the import has completed.
  #
  # @example
  #   summary.record(:created, index: 4)
  #   summary.record(:unchanged, index: 9)
  #   summary.record(:invalid, index: 17, errors: [
  #     Importu::InvalidRecord.new("contains non utf8 characters")
  #   ])
  #
  # @param result [:created, :invalid, :unchanged, :updated] the result of
  #   trying to import the record.
  # @param index [Integer] A zero-indexed position of the record relative
  #   to where it was read from the source data.
  # @param errors [Array<Importu::InvalidRecord>] A list of errors
  #   encountered while converting or importing the record.
  # @return [void]
  #
  # @api semipublic
  def record(result, index: nil, errors: [])
    @total += 1

    case result
      when :created then @created += 1
      when :updated then @updated += 1
      when :unchanged then @unchanged += 1
      when :invalid then
        @invalid += 1
        record_errors(errors, index: index)
    end
  end

  # An aggregated summary of results meant for human consumption, such
  # as displaying in a terminal window. If any errors were encountered
  # during the import, an aggregated list of error messages and the
  # number of times each error was encountered will also be included.
  #
  # @example
  #   puts summary.result_msg
  #
  #   Total:     36
  #   Created:   2
  #   Updated:   1
  #   Invalid:   3
  #   Unchanged: 30
  #
  #   Validation Errors:
  #     - description is required: 3
  #     - title is too long: 2
  #
  # @return [String] a human-readable aggregate summary of results suitable
  #   for displaying in a terminal window.
  #
  # @api public
  def result_msg
    msg = <<-END.gsub(/^\s*/, "")
      Total:     #{total}
      Created:   #{created}
      Updated:   #{updated}
      Invalid:   #{invalid}
      Unchanged: #{unchanged}
    END

    if validation_errors.any?
      msg << "\nValidation Errors:\n"
      msg << validation_errors.map {|e,c| "  - #{e}: #{c}" }.join("\n")
    end

    msg
  end

  # An aggregated summary of results that can be used by a custom formatter,
  # or for any purpose by software interacting with this gem.
  #
  # @example
  #   summary.to_hash
  #
  #   {
  #     :created => 2,
  #     :invalid => 3,
  #     :total => 36,
  #     :unchanged => 30,
  #     :updated => 1,
  #     :validation_errors => {
  #       "description is required" => 3,
  #       "title is too long" => 2
  #     }
  #   }
  #
  # @return [Hash<Symbol=>Integer,Hash>] a hash of
  #   aggregated results. Top-level keys are always symbols with all values
  #   being integers except for :validation_errors; :validation_errors
  #   will always contain a nested hash of error messages and their counts,
  #   with each error message keys being represented as a string.
  #
  # @api public
  def to_hash
    {
      created: created,
      invalid: invalid,
      total: total,
      unchanged: unchanged,
      updated: updated,
      validation_errors: validation_errors,
    }
  end

  alias_method :to_s, :result_msg

  # Updates error attributes to include the newly encountered errors.
  #
  # @todo This method contains code that is meant to scrub/normalize some
  #   ActiveRecord-based error messages. If the error messages are not
  #   scrubbed then they can not be aggregated and will produce a very long
  #   list of errors if there are a large number of invalid records.
  #
  #   The logic should be extracted into the ActiveRecord backend, with the
  #   Importu::InvalidRecord exception storing both a full error message and
  #   a normalized version that can be passed in during initialization.
  #
  # @return [void]
  #
  # @api private
  private def record_errors(errors, index: nil)
    errors.each do |error|
      # Strip parts of error that might be specific to record. Values within
      # parens is assumed to be data, e.g. "Dupe record found (sysnum 5489x)".
      # Originally done due to being an ActiveRecord convention.
      normalized_error = error.to_s.gsub(/ *\([^)]+\) *$/, "")
      @validation_errors[normalized_error] += 1
    end

    @itemized_errors[index] += errors if index
  end

end
