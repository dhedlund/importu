require "bigdecimal"

module Importu::Converters
  def self.included(base)
    base.class_eval do

      converter :boolean do |name|
        value = trimmed(name)
        case value
          when nil then nil
          when true, 1, /\A(?:true|yes|1)\z/i then true
          when false, 0, /\A(?:false|no|0)\z/i then false
          else raise ArgumentError, "invalid boolean value '#{value}'"
        end
      end

      converter :date do |name, format: nil|
        if value = trimmed(name)
          format \
            ? Date.strptime(value, format)
            : Date.parse(value)
        end
      end

      converter :datetime do |name, format: nil|
        if value = trimmed(name)
          format \
            ? DateTime.strptime(value, format).to_time.utc
            : DateTime.parse(value).to_time.utc
        end
      end

      converter :decimal do |name|
        value = trimmed(name)
        case value
          when nil then nil
          when BigDecimal then value
          when /\A-?\d+(?:\.\d+)?\Z/ then BigDecimal(value)
          else raise ArgumentError, "invalid decimal value '#{value}'"
        end
      end

      converter :float do |name|
        value = trimmed(name)
        value.nil? ? nil : Float(value)
      end

      converter :integer do |name|
        value = trimmed(name)

        case value
          when nil then nil
          when Integer then value
          else Integer(value.to_s, 10)
        end
      end

      converter :string do |name|
        value = trimmed(name)
        value.nil? ? nil : String(value)
      end

      converter :trimmed do |name|
        value = raw_value(name)
        if value.is_a?(String)
          new_value = value.strip
          new_value.empty? ? nil : new_value
        else
          value
        end
      end

      converter :default, &convert_to(:trimmed)

    end
  end
end
