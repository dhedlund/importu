require "tempfile"
require "set"

require "importu/backends"
require "importu/converter_context"
require "importu/converters"
require "importu/definition"
require "importu/duplicate_manager"
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
  end

  def config
    self.class.config
  end

  def import!
    summary = Importu::Summary.new
    backend = with_dupe_detection(@backend || backend_from_config)

    records.each.with_index do |record, idx|
      import_record(backend, record, idx, summary)
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

  private def backend_from_config
    backend_class = self.class.backend_registry.from_config!(config[:backend])
    backend_class.new(config[:backend])
  end

  private def enforce_allowed_actions!(action)
    allowed_actions = config[:backend][:allowed_actions]
    if action == :create && !allowed_actions.include?(:create)
      raise Importu::InvalidRecord, "not allowed to create record"
    elsif action == :update && !allowed_actions.include?(:update)
      raise Importu::InvalidRecord, "not allowed to update record"
    end
  end

  private def import_record(backend, record, index, summary)
    begin
      object = backend.find(record)

      if object.nil?
        enforce_allowed_actions!(:create)
        result, object = backend.create(record)
      else
        enforce_allowed_actions!(:update)
        result, object = backend.update(record, object)
      end

      summary.record(result, index: index)

    rescue Importu::InvalidRecord => e
      errors =  e.validation_errors || ["#{e.name}: #{e.message}"]
      summary.record(:invalid, index: index, errors: errors)
    end
  end

  private def with_dupe_detection(backend)
    Importu::DuplicateManager::BackendProxy.new(backend, config[:backend])
  end

end
