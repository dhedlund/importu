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

  def initialize(source, backend: nil)
    @source = source
    @backend = backend
    @context = Importu::ConverterContext.with_config(config)
  end

  def self.backend_middleware
    [
      EnforceAllowedActionsProxy,
      Importu::DuplicateManager::BackendProxy,
    ]
  end

  def self.backend_registry
    Importu::Backends.registry
  end

  def config
    self.class.config
  end

  def import!
    summary = Importu::Summary.new
    backend = with_middleware(@backend || backend_from_config)

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

  private def import_record(backend, record, index, summary)
    begin
      object = backend.find(record)

      result, object = object.nil? \
        ? backend.create(record)
        : backend.update(record, object)

      summary.record(result, index: index)

    rescue Importu::InvalidRecord => e
      errors =  e.validation_errors || ["#{e.name}: #{e.message}"]
      summary.record(:invalid, index: index, errors: errors)
    end
  end

  private def with_middleware(orig_backend)
    self.class.backend_middleware.inject(orig_backend) do |backend,middleware|
      middleware.new(backend, config[:backend])
    end
  end

  class EnforceAllowedActionsProxy < SimpleDelegator

    def initialize(backend, allowed_actions:, **)
      super(backend)
      @allowed_actions = allowed_actions
    end

    def create(record)
      if @allowed_actions.include?(:create)
        super
      else
        raise Importu::InvalidRecord, "not allowed to create record"
      end
    end

    def update(record, object)
      if @allowed_actions.include?(:update)
        super
      else
        raise Importu::InvalidRecord, "not allowed to update record"
      end
    end
  end

end
