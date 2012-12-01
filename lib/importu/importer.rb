require 'active_record/errors'

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
    @outfile ||= Tempfile.new('import', Rails.root.join('tmp'), 'wb+')
  end

  def import!(finder_scope = nil, &block)
    # if a scope is passed in, that scope becomes the starting scope used by
    # the finder, otherwise the model's default scope is used).

    finder_scope ||= model_class.scoped
    records.each {|r| import_record(r, finder_scope, &block) }
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


  protected

  def model_class
    @model_class ||= model.constantize
  end

  def import_record(record, finder_scope, &block)
    begin
      object = find(finder_scope, record) || model_class.new
      action = object.new_record? ? :create : :update
      check_duplicate(object) if action == :update

      case ([action] - allowed_actions).first
        when :create then raise Importu::InvalidRecord, "#{model} not found"
        when :update then raise Importu::InvalidRecord, "existing #{model} found"
      end

      record.assign_to(object, action, &block)

      if object.changed?
        object.save!
        case action
          when :create then @created += 1
          when :update then @updated += 1
        end
      else
        @unchanged += 1
      end

    rescue ActiveRecord::RecordInvalid => e
      #convention:  assume data-specific error messages put data inside parens, e.g. 'Dupe record found (sysnum 5489x)'
      object.errors.full_messages.each {|e| @validation_errors[e.gsub(/ *\([^)]+\)/,'')] += 1 }  
      @invalid += 1

      errors = object.errors.map do |name,message|
        if name=="base"
          message
        else
          name = definitions[name][:label] if definitions[name]
          "#{name} #{message}"
        end
      end.join(', ')

      raise Importu::InvalidRecord, errors

    rescue Importu::InvalidRecord => e
      @validation_errors["#{e.name}: #{e.message}"] += 1
      @invalid += 1
      raise e
    ensure
      @total += 1
    end
  end

  def find(scope, record)
    # FIXME: find does not report if it finds more than one record matching
    # the :find_by conditions passed in.  it just uses the first match for
    # now.  what should be the correct behaviour?

    field_groups = self.class.finder_fields or return
    field_groups.each do |field_group|
      if field_group.respond_to?(:call) # proc
        object = scope.instance_exec(record, &field_group).first
      else
        conditions = Hash[field_group.map {|f| [f, record[f]]}]
        object = scope.where(conditions).first
      end

      return object if object
    end
    nil
  end

  def check_duplicate(record)
    return unless id = record.respond_to?(:id) && record.id
    if ((@encountered||=Hash.new(0))[id] += 1) > 1
      raise Importu::DuplicateRecord, 'matches a previously imported record'
    end
  end

end
