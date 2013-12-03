require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash/deep_dup'
require 'active_support/core_ext/hash/keys'
require 'active_support/concern'

require 'importu/core_ext/deep_freeze'

# importer definition examples:
#   allow_actions :create
#   allow_actions :create, :update
#
#   find_by :id # match against a single field, :id (default)
#   find_by [:name, :date] # match against multiple fields
#   find_by :id, [:name, :date] # try name/date combo if no id match
#   find_by nil # never try to look up records, assume :create
#   find_by do |record|
#     scoped.where(:foo => record[:name].downcase)
#   end
#
#   field  :field1, :label => 'Field 1'
#   fields :field1, :field2, :field3
#   fields :field1, :field2, convert_to(:integer)
#   fields :field1, :field2 do |data,definition|
#     Time.strptime(data[definition[:label]], '%d/%m/%Y')
#   end
#
# allow actions:
#   :create - if an existing record can't be found, we can create it
#   :update - if an existing record found, update its attributes
#
# field(s) definition options:
#   :label - header/label/key/element name used in input file (default: field name)
#   :required - must be present in input file (values can be blank, default: true)

require 'active_support/concern'

module Importu::Dsl
  extend ActiveSupport::Concern

  included do
    config_dsl :record_class, :default => Importu::Record
    config_dsl :model, :description
    config_dsl :allowed_actions, :default => [:create]
    config_dsl :finder_fields, :default => [[:id]]
    config_dsl :definitions, :default => {}
    config_dsl :preprocessor, :postprocessor
    config_dsl :converters, :default => {}
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
      options = fields.extract_options!.symbolize_keys!

      @definitions ||= definitions.deep_dup
      fields.compact.each do |field_name|
        definition = (@definitions[field_name]||{}).merge(options)

        definition[:name] = field_name
        definition[:label] ||= (options['label'] || field_name).to_s
        definition[:required] = true unless definition.key?(:required)
        definition[:create] = true unless definition.key?(:create)
        definition[:update] = true unless definition.key?(:update)

        definition[:converter] = block if block
        definition[:converter] ||= converters[:clean]

        @definitions[field_name] = definition
      end

      return
    end

    alias_method :field, :fields

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

    def config_dsl(*methods)
      options = methods.extract_options!
      options.assert_valid_keys(:default)
      default = (options[:default] || nil).deep_freeze

      methods.each do |m|
        instance_variable_set("@#{m}", default)

        singleton_class.send(:define_method, m) do |*args,&block|
          if block || !args.empty?
            val = (block ? instance_eval(&block) : args[0])
            instance_variable_set("@#{m}", val.deep_freeze)
          else
            instance_variable_defined?("@#{m}") \
              ? instance_variable_get("@#{m}")
              : superclass.send(m)
          end
        end
      end

      # make dsl methods available to importer instances
      delegate *methods, :to => :singleton_class
    end
  end

end
