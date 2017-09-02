class Importu::Importer
  attr_reader :options, :infile, :outfile, :validation_errors
  attr_reader :total, :invalid, :created, :updated, :unchanged

  include Importu::Dsl
  include Importu::Converters

  def initialize(infile, options = {})
    @options = options
    @total = @invalid = @created = @updated = @unchanged = 0
    @validation_errors = Hash.new(0) # counter for each validation error

    @infile = infile.respond_to?(:readline) ? infile : File.open(infile, 'rb')
  end

  def records
    [].to_enum # implement in a subclass
  end

  def outfile
    @outfile ||= Tempfile.new('import', Rails.root.join('tmp'))
  end

  def import!(&block)
    records.each {|r| import_record(r, &block) }
  end

  def result_msg
    msg = <<-END.strip_heredoc
      Total:     #{@total}
      Created:   #{@created}
      Updated:   #{@updated}
      Invalid:   #{@invalid}
      Unchanged: #{@unchanged}
    END

    if @validation_errors.any?
      msg << "\nValidation Errors:\n"
      msg << @validation_errors.map {|e,c| "  - #{e}: #{c}" }.join("\n")
    end

    msg
  end


  protected def enforce_allowed_actions!(action)
    if action == :create && !allowed_actions.include?(:create)
      raise Importu::InvalidRecord, "#{model} not found"
    elsif action == :update && !allowed_actions.include?(:update)
      raise Importu::InvalidRecord, "existing #{model} found"
    end
  end

  protected def import_record(record, &block)
    begin
      object = backend.find(record)

      if object.nil?
        enforce_allowed_actions!(:create)
        result = backend.create(record, &block)
        # FIXME: mark_encountered(object) ?
      else
        enforce_allowed_actions!(:update)
        check_duplicate!(backend, object) # FIXME: Should come before action enforcement?
        result = backend.update(record, object, &block)
        # FIXME: mark_encountered(object) ?
      end

      case result
        when :created   then @created   += 1
        when :updated   then @updated   += 1
        when :unchanged then @unchanged += 1
      end

    rescue Importu::InvalidRecord => e
      # FIXME: Some of this may be ActiveRecord specific?
      if errors = e.validation_errors
        # convention: assume data-specific error messages put data inside parens, e.g. 'Dupe record found (sysnum 5489x)'
        errors.each {|error| @validation_errors[error.gsub(/ *\([^)]+\)/,'')] += 1 }     
      else
        @validation_errors["#{e.name}: #{e.message}"] += 1
      end

      @invalid += 1
      raise

    ensure
      @total += 1
    end
  end

  protected def check_duplicate!(backend, object)
    object_key = backend.object_key(object) or return
    if ((@encountered||=Hash.new(0))[object_key] += 1) > 1
      raise Importu::DuplicateRecord, 'matches a previously imported record'
    end
  end

  private def backend
    @backend ||= begin
      backend_impl = Importu::Backends.registry.lookup(:active_record)
      backend_impl.new(definition)
    end
  end

  private def definition
    self.class
  end

end
