# frozen_string_literal: true
require "bigdecimal"
require "date"

# Built-in converters for common data types.
#
# This module is automatically included in importers and provides these converters:
#
# ## :boolean
# Converts to true/false. Accepts: true, false, 1, 0, "true", "false", "yes", "no".
# Returns nil for nil/empty, raises ArgumentError for other values.
#
#     field :active, &convert_to(:boolean)
#
# ## :date
# Parses date strings. Uses Date.parse by default, or Date.strptime with format option.
#
#     field :published, &convert_to(:date)
#     field :published, &convert_to(:date, format: "%Y-%m-%d")
#
# ## :datetime
# Parses datetime strings to Time (UTC). Uses DateTime.parse or strptime with format.
#
#     field :created_at, &convert_to(:datetime)
#     field :created_at, &convert_to(:datetime, format: "%Y-%m-%d %H:%M:%S")
#
# ## :decimal
# Converts to BigDecimal. Accepts numeric strings like "123.45".
# Returns nil for nil/empty, raises ArgumentError for invalid format.
#
#     field :price, &convert_to(:decimal)
#
# ## :float
# Converts to Float using Kernel#Float.
#
#     field :rating, &convert_to(:float)
#
# ## :integer
# Converts to Integer (base 10). Accepts integers or numeric strings.
#
#     field :pages, &convert_to(:integer)
#
# ## :string
# Converts to String. Trims whitespace, returns nil for empty strings.
#
#     field :name, &convert_to(:string)
#
# ## :trimmed (default)
# Strips whitespace from strings, returns nil for empty. Non-strings pass through.
# This is the default converter when none is specified.
#
#     field :title  # uses :trimmed by default
#
# @see Importu::ConfigDSL#converter
# @see Importu::ConfigDSL#convert_to
# @api semipublic
module Importu::Converters
  # Defines built-in converters when included in a class.
  #
  # @api private
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
          dt = format \
            ? DateTime.strptime(value, format)
            : DateTime.parse(value)
          # Convert DateTime to Time without triggering ActiveSupport deprecation
          offset_seconds = (dt.offset * 86_400).to_i
          Time.new(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec, offset_seconds).utc
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
