require "ice_nine"

require "importu/record"

# importer definition examples:
#   allow_actions :create
#   allow_actions :create, :update
#
#   find_by :id # match against a single field, :id (default)
#   find_by [:name, :date] # match against multiple fields
#   find_by :id, [:name, :date] # try name/date combo if no id match
#   find_by nil # never try to look up records, assume :create
#   find_by do |record|
#     scoped.where(foo: record[:name].downcase)
#   end
#
#   field  :field1, label: "Field 1"
#   fields :field1, :field2, :field3
#   fields :field1, :field2, convert_to(:integer)
#   fields :field1, :field2 do |data,definition|
#     Time.strptime(data[definition[:label]], "%d/%m/%Y")
#   end
#
# allow actions:
#   :create - if an existing record can't be found, we can create it
#   :update - if an existing record found, update its attributes
#
# field(s) definition options:
#   :label - header/label/key/element name used in input file (default: field name)
#   :required - must be present in input file (values can be blank, default: true)

module Importu::Dsl
  def self.included(base)
    base.extend Forwardable
    base.extend ClassMethods
    base.class_eval do
      config_dsl :record_class, default: Importu::Record
      config_dsl :description
      config_dsl :allowed_actions, default: [:create]
      config_dsl :finder_fields, default: [[:id]]
      config_dsl :field_definitions, default: {}
      config_dsl :preprocessor
      config_dsl :postprocessor
      config_dsl :converters, default: {}

      # FIXME: source-specific setting, here until we have a way to define
      # source and backend-specific configurations from their own classes.
      config_dsl :records_xpath # Importu::Sources::XML
    end
  end

  module ClassMethods
    def allow_actions(*actions)
      @allowed_actions = actions
    end

    def find_by(*field_groups, &block)
      @finder_fields = block ? [block] : field_groups.map {|g|g&&[*g]}.compact
    end

    def fields(*fields, &block)
      block = fields.pop if fields.last.kind_of?(Proc)
      options = fields.last.is_a?(Hash) ? fields.pop : {}
      options = Hash[options.map {|k,v| [k.to_sym, v] }]

      @field_definitions ||= Marshal.load(Marshal.dump(field_definitions))
      fields.compact.each do |field_name|
        definition = (@field_definitions[field_name]||{}).merge(options)

        definition[:name] = field_name
        definition[:label] ||= (options["label"] || field_name).to_s
        definition[:required] = true unless definition.key?(:required)
        definition[:create] = true unless definition.key?(:create)
        definition[:update] = true unless definition.key?(:update)

        definition[:converter] = block if block
        definition[:converter] ||= converters[:clean]

        @field_definitions[field_name] = definition
      end

      return
    end

    alias_method :field, :fields

    def model_backend
      @model_backend
    end

    def model(name = nil, backend: nil)
      if name
        @model = name
        @model_backend = backend
        @model_class = nil # Clear memoized value
      else
        # Defer looking up model class until first use
        @model ||= nil # warning: instance variable @model not initialized
        @model_class ||= @model.is_a?(String) ? const_get(@model) : @model
      end
    end

    def preprocess(&block)
      # gets executed just before record converted to object
      @preprocessor = block
    end

    def postprocess(&block)
      # gets executed just after record converted to object
      @postprocessor = block
    end

    def converter(name, &block)
      @converters = converters.merge(name => block)
    end

    def convert_to(type, options = {})
      converters[type] # FIXME: raise error if not found?
    end

    def config_dsl(meth, default: nil)
      instance_variable_set("@#{meth}", IceNine.deep_freeze(default))

      singleton_class.send(:define_method, meth) do |*args,&block|
        if block || !args.empty?
          val = (block ? instance_eval(&block) : args[0])
          instance_variable_set("@#{meth}", IceNine.deep_freeze(val))
        else
          instance_variable_defined?("@#{meth}") \
            ? instance_variable_get("@#{meth}")
            : superclass.send(meth)
        end
      end

      # make dsl method available to importer instances
      delegate meth => :singleton_class
    end
  end

end
