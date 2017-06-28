require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/concern'

require 'bigdecimal'

module Importu::Converters
  extend ActiveSupport::Concern

  included do
    converter :raw do |name,options|
      definition = definitions[name] \
        or raise Importu::InvalidDefinition, "importer field not defined: #{name}"

      label = definition[:label]
      raise Importu::MissingField, definition unless data.key?(label)
      data[label]
    end

    converter :clean do |name,options|
      value = convert(name, :raw, options)
      value.is_a?(String) \
        ? (value.blank? ? nil : value.strip)
        : value
    end

    converter :string do |name,options|
      convert(name, :clean, options).try(:to_s)
    end

    converter :integer do |name,options|
      value = convert(name, :clean, options)
      value.nil? ? nil : Integer(value)
    end

    converter :float do |name,options|
      value = convert(name, :clean, options)
      value.nil? ? nil : Float(value)
    end

    converter :decimal do |name,options|
      value = convert(name, :clean, options)
      case value
        when nil then nil
        when BigDecimal then value
        when /\A-?\d+(?:\.\d+)?\Z/ then BigDecimal(value)
        else raise ArgumentError, "invalid decimal value '#{value}'"
      end
    end

    converter :boolean do |name,options|
      value = convert(name, :clean, options)
      case value
        when nil then nil
        when true, 'true', 'yes', '1', 1 then true
        when false, 'false', 'no', '0', 0 then false
        else raise ArgumentError, "invalid boolean value '#{value}'"
      end
    end

    converter :date do |name,options|
      if value = convert(name, :clean, options)
        # TODO: options[:date_format] is deprecated
        date_format = options[:date_format] || options[:format]
        date_format \
          ? Date.strptime(value, date_format)
          : Date.parse(value)
      end
    end

    converter :datetime do |name,options|
      if value = convert(name, :clean, options)
        # TODO: options[:date_format] is deprecated
        date_format = options[:date_format] || options[:format]
        date_format \
          ? DateTime.strptime(value, date_format).utc
          : DateTime.parse(value).utc
      end
    end

  end
end
