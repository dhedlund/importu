# frozen_string_literal: true

# DSL methods for configuring importers. These methods are available as class
# methods when extending this module, allowing declarative configuration of
# fields, converters, backends, and sources.
#
# @example Basic usage
#   class BookImporter < Importu::Importer
#     fields :title, :author, :isbn
#     field :pages, &convert_to(:integer)
#     model "Book"
#   end
#
# @api public
module Importu::ConfigDSL

  # Returns the current configuration hash for this importer.
  #
  # @return [Hash] the configuration hash
  # @api semipublic
  def config
    @config ||= superclass.respond_to?(:config) \
      ? superclass.config
      : default_config
  end

  # Specifies which persistence actions are allowed during import.
  #
  # @param actions [Array<Symbol>] the actions to allow (:create and/or :update)
  # @return [void]
  #
  # @example Allow only creating new records (default)
  #   allow_actions :create
  #
  # @example Allow both creating and updating
  #   allow_actions :create, :update
  #
  # @api public
  def allow_actions(*actions)
    @config = { **config,
      backend: { **config[:backend], allowed_actions: actions.compact }
    }
  end

  # Specifies which source types are allowed for this importer.
  #
  # @param sources [Array<Symbol>] the source types to allow (:csv, :json, :xml, :ruby)
  # @return [void]
  #
  # @example Allow only CSV (default)
  #   allow_sources :csv
  #
  # @example Allow multiple source types
  #   allow_sources :csv, :json, :xml
  #
  # @api public
  def allow_sources(*sources)
    @config = { **config, allowed_sources: sources }
  end

  # Creates a converter reference for use with field definitions.
  #
  # @param type [Symbol] the converter type (:string, :integer, :date, etc.)
  # @param options [Hash] converter-specific options
  # @return [ConverterStub] a callable that applies the converter
  #
  # @example Basic usage
  #   field :pages, &convert_to(:integer)
  #
  # @example With options
  #   field :release_date, &convert_to(:date, format: "%Y-%m-%d")
  #
  # @api public
  def convert_to(type, **options)
    config[:converters].fetch(type) # validate converter exists
    ConverterStub.for(type, **options)
  end

  # Defines a custom converter for use in field definitions.
  #
  # @param name [Symbol] the converter name
  # @yield [field_name, **options] block that performs the conversion
  # @yieldparam field_name [Symbol] the field being converted
  # @yieldparam options [Hash] any options passed to convert_to
  # @yieldreturn the converted value
  # @return [void]
  #
  # @example Simple converter
  #   converter(:uppercase) do |name|
  #     value = raw(name)
  #     value.respond_to?(:upcase) ? value.upcase : value
  #   end
  #
  # @example Converter with options
  #   converter(:varchar) do |name, length: 255|
  #     value = trimmed(name)
  #     value.nil? ? nil : String(value).slice(0, length)
  #   end
  #
  # @api public
  def converter(name, &block)
    @config = { **config,
      converters: { **config[:converters], name => block }
    }
  end

  # Defines a single field with its configuration.
  #
  # @param name [Symbol] the field name (used as the key in record hashes)
  # @param props [Hash] field options
  # @option props [String] :label the column/key name in source data (default: field name as string)
  # @option props [Boolean] :required whether the field must be present (default: true)
  # @option props [Boolean] :abstract whether the field is computed, not from source (default: false)
  # @option props [Object] :default value to use when field is nil and not required
  # @option props [Boolean] :create include this field when creating records (default: true)
  # @option props [Boolean] :update include this field when updating records (default: true)
  # @yield [field_name] optional block for custom conversion logic
  # @return [void]
  #
  # @example Basic field
  #   field :title
  #
  # @example Field with label mapping
  #   field :authors, label: "author"
  #
  # @example Field with converter
  #   field :pages, &convert_to(:integer)
  #
  # @example Field with custom conversion block
  #   field :authors do
  #     trimmed(:authors).to_s.split(", ")
  #   end
  #
  # @api public
  def field(name, **props, &block)
    field = config[:fields].fetch(name, field_defaults(name))
    props[:converter] = block if block

    @config = { **config,
      fields: { **config[:fields],
        name => { **field, **props }
      }
    }
  end

  # Defines multiple fields with the same configuration.
  #
  # @param names [Array<Symbol>] the field names
  # @param props [Hash] field options (see {#field} for available options)
  # @yield optional block for custom conversion (applied to all fields)
  # @return [void]
  #
  # @example Multiple fields
  #   fields :title, :author, :isbn
  #
  # @example Multiple fields with shared converter
  #   fields :pages, :quantity, &convert_to(:integer)
  #
  # @api public
  def fields(*names, **props, &block)
    names.each {|name| field(name, **props, &block) }
  end

  # Specifies how to find existing records for updates.
  #
  # @param field_groups [Array<Symbol, Array<Symbol>>] fields to match against
  # @yield [record] optional block for custom lookup logic
  # @yieldparam record [Importu::Record] the record being imported
  # @return [void]
  #
  # @example Single field lookup
  #   find_by :isbn
  #
  # @example Multiple fields (all must match)
  #   find_by :title, :author
  #
  # @example Multiple field groups (tried in order)
  #   find_by :isbn, [:title, :author]
  #
  # @example Custom lookup block
  #   find_by do |record|
  #     find_by(title: record[:title].downcase)
  #   end
  #
  # @api public
  def find_by(*field_groups, &block)
    finder_fields = [*field_groups, block].compact.map do |field_group|
      field_group.respond_to?(:call) ? field_group : Array(field_group)
    end

    @config = { **config,
      backend: { **config[:backend], finder_fields: finder_fields }
    }
  end

  # Associates the importer with a model class for persistence.
  #
  # @param name [String, Class] the model class or class name
  # @param backend [Symbol, nil] the backend to use (:active_record, :auto, or nil)
  # @return [void]
  #
  # @example Basic usage
  #   model "Book"
  #
  # @example With explicit backend
  #   model "Book", backend: :active_record
  #
  # @example With auto-detection (default behavior)
  #   model "Book", backend: :auto
  #
  # The backend can be:
  # - nil or :auto - auto-detect from registered backends
  # - :active_record - use ActiveRecord backend explicitly
  # - Any other symbol registered with Importu::Backends.registry
  #
  # @see #allow_actions
  # @see #find_by
  # @api public
  def model(name, backend: nil)
    @config = { **config,
      backend: { **config[:backend], name: backend, model: name }
    }
  end

  # Defines a callback to execute just before saving a record.
  #
  # The block is executed in the context of an AssignmentContext, which
  # provides access to:
  # - object: the model instance being saved
  # - record: the converted record data
  # - action: :create or :update
  #
  # This is a backend hook. Backends may choose to honor it or ignore it.
  # The ActiveRecord backend executes it after assigning field values but
  # before calling save!.
  #
  # @yield block to execute before saving
  # @return [void]
  #
  # @example Normalize title before saving
  #   before_save { object.title = object.title.titleize }
  #
  # @example Set audit field
  #   before_save { object.imported_at = Time.current }
  #
  # @example Conditional logic based on action
  #   before_save do
  #     object.created_by = "importer" if action == :create
  #     object.updated_by = "importer" if action == :update
  #   end
  #
  # @see Importu::Backends::ActiveRecord::AssignmentContext
  # @api public
  def before_save(&block)
    @config = { **config,
      backend: { **config[:backend], before_save: block }
    }
  end

  # Configures source-specific options.
  #
  # @param type [Symbol] the source type (:csv, :json, :xml, :ruby)
  # @param props [Hash] source-specific options
  # @return [void]
  #
  # @example XML source with xpath
  #   source :xml, records_xpath: "//book"
  #
  # @example CSV source with custom delimiter
  #   source :csv, col_sep: "\t"
  #
  # @api public
  def source(type, **props)
    source = config[:sources].fetch(type, {})

    @config = { **config,
      sources: { **config[:sources],
        type => { **source, **props }
      }
    }
  end

  # @!visibility private
  def default_config
    raw_converter = ->(n) { raw_value(n) }

    {
      allowed_sources: [:csv],
      backend: {
        name: nil,
        model: nil,
        finder_fields: [],
        before_save: nil,
        allowed_actions: [:create],
      },
      sources: {
        csv: {},
        json: {},
        ruby: {},
        xml: {
          records_xpath: nil,
        },
      },
      converters: {
        raw: raw_converter,
        default: raw_converter,
      },
      fields: {},
    }
  end

  # @!visibility private
  def field_defaults(name)
    {
      name: name,
      label: name.to_s,
      required: true,
      abstract: false,
      default: nil,
      create: true,
      update: true,
      converter: convert_to(:default),
    }
  end

  # A proc-like object that stores converter type and options.
  #
  # This allows subclassed definitions to override a converter's behavior
  # and have it affect already defined fields.
  #
  # @api private
  class ConverterStub < Proc
    # @return [Symbol] the converter type
    attr_reader :type

    # @return [Hash] the converter options
    attr_reader :options

    # Creates a new converter stub.
    #
    # @param type [Symbol] the converter type
    # @param options [Hash] options to pass to the converter
    # @param block [Proc] the converter implementation
    def initialize(type, options, &block)
      @type, @options = type, options
      super(&block)
    end

    # Creates a stub that delegates to a named converter.
    #
    # @param type [Symbol] the converter type
    # @param options [Hash] options to pass to the converter
    # @return [ConverterStub] a new stub
    def self.for(type, **options)
      block = options.any? \
        ? ->(n) { send(type, n, **options) }
        : ->(n) { send(type, n) }

      new(type, options, &block)
    end

    # Compares stubs by type and options.
    #
    # @param other [ConverterStub] the other stub
    # @return [Boolean] true if type and options match
    def ==(other)
      type == other.type && options == other.options
    end
  end

end
