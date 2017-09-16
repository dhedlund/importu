require "importu/backends"
require "importu/converters"
require "importu/definition"
require "importu/exceptions"
require "importu/record"
require "importu/summary"

class Importu::Importer

  extend Importu::ConfigDSL
  include Importu::Converters

  attr_reader :source

  def initialize(source, backend: nil, definition: nil)
    @source = source
    @backend = backend
    @definition = definition || self.class
    @context = Importu::ConverterContext.with_config(config)
  end

  def self.backend_registry
    Importu::Backends.registry
  end

  def config
    @definition.config
  end

  def import!(recorder = Importu::Summary.new)
    backend = with_middleware(@backend || backend_from_config)

    records.each.with_index do |record, idx|
      import_record(backend, record, idx, recorder)
    end
    recorder
  end

  def records
    Importu::Record::Iterator.new(@source.rows, config)
  end

  private def backend_from_config
    backend_class = self.class.backend_registry.from_config!(config[:backend])
    backend_class.new(config[:backend])
  end

  private def import_record(backend, record, index, recorder)
    begin
      object = backend.find(record)

      result, object = object.nil? \
        ? backend.create(record)
        : backend.update(record, object)

      recorder.record(result, index: index)

    rescue Importu::InvalidRecord => e
      errors =  e.validation_errors || ["#{e.name}: #{e.message}"]
      recorder.record(:invalid, index: index, errors: errors)
    end
  end

  private def with_middleware(orig_backend)
    Importu::Backends.middleware.inject(orig_backend) do |backend,middleware|
      middleware.new(backend, config[:backend])
    end
  end

end
