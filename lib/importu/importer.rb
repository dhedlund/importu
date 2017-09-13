require "tempfile"
require "set"

require "importu/backends"
require "importu/converter_context"
require "importu/converters"
require "importu/definition"
require "importu/exceptions"
require "importu/record"
require "importu/summary"

class Importu::Importer

  extend Importu::Definition
  include Importu::Converters

  attr_reader :source, :context

  def self.backend_registry
    Importu::Backends.registry
  end

  def initialize(source, backend: nil)
    @source = source
    @backend = backend
    @context = Importu::ConverterContext.with_config(config)
    @encountered = Set.new
  end

  def config
    self.class.config
  end

  def import!
    @encountered.clear
    summary = Importu::Summary.new
    records.each.with_index do |record, idx|
      import_record(record, idx, summary)
    end
    summary
  end

  def records
    Enumerator.new do |yielder|
      @source.rows.each do |data|
        yielder.yield Importu::Record.new(data, context, config)
      end
    end
  end

  private def enforce_allowed_actions!(action)
    allowed_actions = config[:allowed_actions]
    if action == :create && !allowed_actions.include?(:create)
      raise Importu::InvalidRecord, "not allowed to create record"
    elsif action == :update && !allowed_actions.include?(:update)
      raise Importu::InvalidRecord, "not allowed to update record"
    end
  end

  private def import_record(record, index, summary)
    begin
      object = backend.find(record)

      if object.nil?
        enforce_allowed_actions!(:create)
        result, object = backend.create(record)
      else
        check_duplicate!(backend, object)
        enforce_allowed_actions!(:update)
        result, object = backend.update(record, object)
      end

      mark_encountered(object)
      summary.record(result, index: index)

    rescue Importu::InvalidRecord => e
      errors =  e.validation_errors || ["#{e.name}: #{e.message}"]
      summary.record(:invalid, index: index, errors: errors)
    end
  end

  private def check_duplicate!(backend, object)
    object_key = backend.object_key(object) or return

    if @encountered.include?(object_key)
      raise Importu::DuplicateRecord, "matches a previously imported record"
    end

    @encountered.add(object_key)
  end

  private def mark_encountered(object)
    object_key = backend.object_key(object) or return
    @encountered.add(object_key)
  end

  private def backend
    @backend ||= begin
      backend_class = self.class.backend_registry.from_config!(config[:backend])
      backend_class.new(config[:backend])
    end
  end

end
