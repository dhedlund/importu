class Importu::Summary

  attr_reader :created, :invalid, :total, :unchanged, :updated
  attr_reader :validation_errors, :itemized_errors

  def initialize
    @total = @invalid = @created = @updated = @unchanged = 0
    @validation_errors = Hash.new(0) # counter for each validation error

    # Sparse array of error messages grouped by the index of the record.
    # Should stay ordered by index because rows are processed sequentially
    # and hashes preserve insertion order. Recorded errors without an index
    # will be ignored. Index is 0-based from first record.
    @itemized_errors = Hash.new {|h,idx| h[idx] = [] }
  end

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
