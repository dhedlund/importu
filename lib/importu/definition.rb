module Importu::Definition

  def config
    @config ||= begin
      superclass.respond_to?(:config) \
        ? superclass.config
        : default_config
    end
  end

  # allow_actions :create
  # allow_actions :create, :update
  #
  # allow actions:
  #   :create - if an existing record can't be found, we can create it
  #   :update - if an existing record found, update its attributes
  def allow_actions(*actions)
    @config = { **config, allowed_actions: actions }
  end

  # Source types that are allowed to be autodetected from an input file.
  # When an input file is given during importer initialization, the list
  # of allowed sources will be checked, in order, for one that is compatible
  # with the input file.
  #
  # allow_sources :csv
  # allow_sources :csv, :json, :xml
  def allow_sources(*sources)
    @config = { **config, allowed_sources: sources }
  end

  def convert_to(type, **options)
    converter = config[:converters].fetch(type)
    ConverterStub.for(type, options)
  end

  # converter(:uppercase) do |name|
  #   value = raw(name)
  #   value.respond_to?(:upcase) ? value.upcase : value
  # end
  #
  # converter(:varchar) do |name, length: 255|
  #   value = raw(name)
  #   value.is_a?(String) ? name.slice(0, length) : value
  # end
  #
  # converter :default, &convert_to(:varchar, length: 255)
  def converter(name, &block)
    @config = { **config,
      converters: { **config[:converters], name => block }
    }
  end

  # field  :field1, label: "Field 1"
  #
  # field(s) definition options:
  #   :label - header/label/key/element name used in input file (default: field name)
  #   :required - must be present in input file (values can be blank, default: true)
  def field(name, **props, &block)
    field = config[:fields].fetch(name, field_defaults(name))
    props.merge!(converter: block) if block

    @config = { **config,
      fields: { **config[:fields],
        name => { **field, **props }
      }
    }
  end

  # fields :field1, :field2, :field3
  # fields :field1, :field2, convert_to(:integer)
  # fields :field1, :field2 do |data,definition|
  #   Time.strptime(data[definition[:label]], "%d/%m/%Y")
  # end
  def fields(*names, **props, &block)
    names.each {|name| field(name, props, &block) }
  end

  # find_by :id # match against a single field, :id (default)
  # find_by [:name, :date] # match against multiple fields
  # find_by :id, [:name, :date] # try name/date combo if no id match
  # find_by nil # never try to look up records, assume :create
  # find_by do |record|
  #   find_by(foo: record[:name].downcase)
  # end
  def find_by(*field_groups, &block)
    finder_fields = block ? [block] : field_groups.compact
    @config = { **config,
      backend: { **config[:backend], finder_fields: finder_fields }
    }
  end

  # FIXME: Can we make `backend` support :auto or :autodetect
  def model(name, backend: nil)
    @config = { **config,
      backend: { **config[:backend], name: backend, model: name }
    }
  end

  # FIXME: backend-specific setting, should be mixed in from somewhere else.
  # Block to execute just before saving the model object to the database.
  def before_save(&block)
    @config = { **config,
      backend: { **config[:backend], before_save: block }
    }
  end

  # FIXME: source-specific setting, here until we have a way to define
  # source and backend-specific configurations from their own classes.
  # Should also have value moved into a [:sources][:xml] field.
  def records_xpath(xpath)
    @config = { **config,
      sources: { **config[:sources],
        xml: { **config[:sources][:xml], records_xpath: xpath }
      }
    }
  end

  # Define source-specific options. When autodetecting sources from the
  # `allowed_sources` list, these options will be passed to the source
  # during initialization.
  #
  # source :xml, records_xpath: "//books"
  # source :csv, col_sep: "\t"
  def source(type, **props, &block)
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
      allowed_actions: [:create],
      allowed_sources: [:csv],
      backend: {
        name: nil,
        model: nil,
        finder_fields: [[:id]],
        before_save: nil,
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

  # @!visibility private
  # A proc-like object that stores info about how to call the converter
  # in the future from within a ConverterContext. This allows subclassed
  # definitions to override a converter's behavior and have it affect
  # already defined fields.
  class ConverterStub < Proc
    attr_reader :type, :options

    def initialize(type, options)
      @type, @options = type, options
    end

    def self.for(type, **options)
      block = options.any? \
        ? ->(n) { send(type, n, options) }
        : ->(n) { send(type, n) }

      new(type, options, &block)
    end

    def ==(other)
      type == other.type && options == other.options
    end
  end

end
