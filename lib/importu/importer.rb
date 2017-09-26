require "importu/backends"
require "importu/converters"
require "importu/definition"
require "importu/exceptions"
require "importu/record"
require "importu/summary"

# An importer provides a public interface for performing an import. It is
# where different Importu components are put together to get data from a
# source into the backend.
class Importu::Importer

  extend Importu::ConfigDSL
  include Importu::Converters

  # The data source used for generating records
  #
  # @return [#rows]
  #
  # @example
  #   importer.source # => #<Importu::Backends::CSV: ...>
  #
  # @api public
  attr_reader :source

  # Creates a new instance of an importer.
  #
  # @example
  #   Importu::Importer.new # => #<Importu::Importer: ...>
  #
  # @param source [#rows] The source to read data from.
  # @param backend [#find, #unique_id, #create, #update] The backend to
  #   persist records to.
  # @param definition [Importu::Definition, nil] A definition/contract to
  #   use for generating records and controlling the import.
  # @return [Importu::Importer]
  #
  # @api public
  def initialize(source, backend: nil, definition: nil)
    @source = source
    @backend = backend
    @definition = definition || self.class
    @context = Importu::ConverterContext.with_config(config)
  end

  # A registry of importer backends available for use.
  #
  # @example
  #   Importu::Importer.backend_registry # => #<Importu::Backends: ...>
  #
  # @return [Importu::Backend]
  #
  # @api semipublic
  def self.backend_registry
    Importu::Backends.registry
  end

  # A hash-based configuration of the definition used by the importer.
  #
  # @return [Hash]
  #
  # @example
  #   importer.config # => { ... }
  #
  # @api semipublic
  def config
    @definition.config
  end

  # Reads data from the source and attempts to create or update records
  # through the backend. A summary of results from the import, including
  # any errors encountered will be returned.
  #
  # If you need a way to track the progress of an import as each record is
  # added, a custom recorder can be provided that can hook into other parts
  # of your system; the recorder's #record method is called after each record
  # has been processed.
  #
  # @example
  #   summary = importer.import!
  #   summary.created # => 2
  #
  #   class CustomRecorder
  #     def record(result, index: nil, errors: [])
  #       puts "record: #{index}: #{result}"
  #     end
  #   end
  #
  #   importer.import!(CustomRecorder.new)
  #   # (stdout) "record 0: created"
  #   # (stdout) "record 1: unchanged"
  #   # ...
  #
  # @param recorder [#record] An optional recorder to use instead of the
  #   default summarizer. Must implement a #record method.
  # @return [Importu::Summary, #record] a summary object, or the same object
  # passed into the method.
  #
  # @api public
  def import!(recorder = Importu::Summary.new)
    backend = with_middleware(@backend || backend_from_config)

    records.each.with_index do |record, idx|
      import_record(backend, record, idx, recorder)
    end
    recorder
  end

  # An iterator of Importu::Record objects from the source data. Each call
  # to the method returns a new iterator from the start.
  #
  # @return [Importu::Record::Iterator]
  #
  # @example
  #   importer.records
  #
  # @api public
  def records
    Importu::Record::Iterator.new(@source.rows, config)
  end

  # Looks for a backend that is compatible with the definition used for
  # the importer.
  #
  # @return [#find, #unique_id, #create, #update]
  # @raise [Importu::BackendMatchError] if a compatible backend could not be
  #   found.
  #
  # @api private
  private def backend_from_config
    backend_class = self.class.backend_registry.from_config!(config[:backend])
    backend_class.new(config[:backend])
  end

  # Performs an import of a single record. Acts as a wrapper around behavior
  # that interfaces with the backend.
  #
  # @return [void]
  #
  # @api private
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

  # Wraps the configured backend with additional behaviors, such as duplicate
  # detection.
  #
  # @return [#find, #unique_id, #create, #update]
  #
  # @api private
  private def with_middleware(orig_backend)
    Importu::Backends.middleware.inject(orig_backend) do |backend,middleware|
      middleware.new(backend, config[:backend])
    end
  end

end
