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

  def convert_to(type, **options)
    block = config[:converters].fetch(type)
    options.any? ? ->(n) { block.call(n, options) } : block
  end

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
  #   where(foo: record[:name].downcase)
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

  # gets executed just before record converted to object
  def preprocess(&block)
    @config = { **config, preprocess: block }
  end

  # gets executed just after record converted to object
  def postprocess(&block)
    @config = { **config, postprocess: block }
  end

  # FIXME: source-specific setting, here until we have a way to define
  # source and backend-specific configurations from their own classes.
  # Should also have value moved into a [:sources][:xml] field.
  def records_xpath(xpath)
    @config = { **config, records_xpath: xpath }
  end

  # @!visibility private
  def default_config
    {
      allowed_actions: [:create],
      backend: {
        name: nil,
        model: nil,
        finder_fields: [[:id]],
      },
      preprocess: nil,
      postprocess: nil,
      records_xpath: nil,
      converters: {},
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
      converter: convert_to(:clean),
    }
  end

end
