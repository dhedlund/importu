require 'bigdecimal'

module Importu::Converters
  def self.included(base)
    base.class_eval do
      converter :raw do |name,options|
        definition = definitions[name] \
          or raise Importu::InvalidDefinition, "importer field not defined: #{name}"

        label = definition[:label]
        raise Importu::MissingField, definition unless data.key?(label)
        data[label]
      end

      converter :clean do |name,options|
        value = convert(name, :raw, options)
        if value.is_a?(String)
          new_value = value.strip
          new_value.empty? ? nil : new_value
        else
          value
        end
      end

      converter :string do |name,options|
        value = convert(name, :clean, options)
        value.nil? ? nil : String(value)
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
            ? DateTime.strptime(value, date_format).to_time.utc
            : DateTime.parse(value).to_time.utc
        end
      end

    end
  end
end
