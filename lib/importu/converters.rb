require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/concern'

require 'bigdecimal'

module Importu::Converters
  extend ActiveSupport::Concern

  included do
    converter :raw do |data,definition|
      label = definition[:label]
      raise Importu::MissingField, label unless data.key?(label)
      data[label]
    end

    converter :clean do |data,definition|
      value = raw(data, definition)
      value.is_a?(String) \
        ? (value.blank? ? nil : value.strip)
        : value
    end

    converter :string do |data,definition|
      clean(data, definition).try(:to_s)
    end

    converter :integer do |data,definition|
      value = clean(data, definition)
      value.nil? ? nil : Integer(value)
    end

    converter :float do |data,definition|
      value = clean(data, definition)
      value.nil? ? nil : Float(value)
    end

    converter :decimal do |data,definition|
      value = clean(data, definition)
      case value
        when nil then nil
        when BigDecimal then value
        when /\A-?\d+(?:\.\d+)?\Z/ then BigDecimal(value)
        else raise ArgumentError, "invalid decimal value '#{value}'"
      end
    end

    converter :boolean do |data,definition|
      value = clean(data, definition)
      case value
        when nil then nil
        when true, 'true', 'yes', '1', 1 then true
        when false, 'false', 'no', '0', 0 then false
        else raise ArgumentError, "invalid boolean value '#{value}'"
      end
    end

    converter :date do |data,definition|
      if value = clean(data, definition)
        date_format = definition[:date_format]
        date_format \
          ? Date.strptime(value, date_format)
          : Date.parse(value)
      end
    end

    converter :datetime do |data,definition|
      if value = clean(data, definition)
        date_format = definition[:date_format]
        date_format \
          ? DateTime.strptime(value, date_format).utc
          : DateTime.parse(value).utc
      end
    end

    converter :field_value do |data,definition|
      # looks up the the converted value of another field
      begin
        converter = definition[:converter]
        converter \
          ? instance_exec(*[data,definition].take(converter.arity), &converter)
          : clean(data, definition)
      rescue ArgumentError => e
        # conversion of field value most likely failed
        raise Importu::FieldParseError, "#{definition[:label]}: #{e.message}"
      end
    end
  end

end
