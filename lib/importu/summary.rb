class Importu::Summary
  attr_reader :created, :invalid, :total, :unchanged, :updated
  attr_reader :validation_errors

  def initialize
    @total = @invalid = @created = @updated = @unchanged = 0
    @validation_errors = Hash.new(0) # counter for each validation error
  end

  def record(result, errors: [])
    @total += 1

    case result
      when :created then @created += 1
      when :updated then @updated += 1
      when :unchanged then @unchanged += 1
      when :invalid then
        @invalid += 1
        record_errors(errors)
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

  def to_s
    result_msg
  end

  private def record_errors(errors)
    errors.each do |error|
      # Strip parts of error that might be specific to record. Values within
      # parens is assumed to be data, e.g. "Dupe record found (sysnum 5489x)".
      # Originally done due to being an ActiveRecord convention.
      normalized_error = error.gsub(/ *\([^)]+\) *$/, "")
      @validation_errors[normalized_error] += 1
    end
  end

end
