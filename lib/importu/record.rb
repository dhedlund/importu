class Importu::Record
  attr_reader :importer, :data, :raw_data

  include Enumerable

  extend Forwardable
  delegate [:keys, :values, :each, :[], :key?] => :record_hash
  delegate [:preprocessor, :postprocessor] => :importer
  delegate [:definitions, :converters] => :importer

  def initialize(importer, data, raw_data)
    @importer, @data, @raw_data = importer, data, raw_data
  end

  def record_hash
    @record_hash ||= generate_record_hash
  end

  def to_hash
    record_hash
  end

  def convert(name, type, options = {})
    type, options = type[:to], type if type.kind_of?(Hash)
    converter = type ? converters[type] : options[:converter] \
      or raise "converter not found: #{type}"

    # TODO: defining options in field definition is deprecated
    definition = definitions[name] || {}
    options = definition.merge(options)

    begin
      value = instance_exec(name, options, &converter)
      value.nil? ? options[:default] : value

    rescue Importu::MissingField => e
      raise e if options[:required]
      options[:default]

    rescue ArgumentError => e
      # conversion of field value most likely failed
      raise Importu::FieldParseError, "#{name}: #{e.message}"
    end
  end

  def field_value(name, options = {})
    definition = definitions[name] \
      or raise "importer field not defined: #{name}"

    convert(name, nil, definition.merge(options))
  end

  def assign_to(object, action, &block)
    @object, @action = object, action

    instance_eval(&preprocessor) if preprocessor
    instance_exec(object, record_hash, &block) if block

    # filter out any fields we're not allowed to copy for this action
    allowed_fields = definitions.select {|n,d| d[action] }.keys
    concrete_fields = definitions.reject {|n,d| d[:abstract] }.keys
    field_names = record_hash.keys & allowed_fields & concrete_fields

    unsupported = field_names.reject {|n| object.respond_to?("#{n}=") }
    if unsupported.any?
      raise "model does not support assigning fields: #{unsupported.to_sentence}"
    end

    (record_hash.keys & allowed_fields & concrete_fields).each do |name|
      if object.respond_to?("#{name}=")
        object.send("#{name}=", record_hash[name])
      else
      end
    end

    instance_eval(&postprocessor) if postprocessor

    object
  end

  if defined?(ActiveRecord)
    def save!
      return :unchanged unless @object.changed?

      begin
        @object.save!
        case @action
          when :create then :created
          when :update then :updated
        end

      rescue ActiveRecord::RecordInvalid => e
        error_msgs = @object.errors.map do |name,message|
          name = definitions[name][:label] if definitions[name]
          name == 'base' ? message : "#{name} #{message}"
        end.join(', ')

        raise Importu::InvalidRecord, error_msgs, @object.errors.full_messages
      end
    end
  else
    def save!
      raise NotImplementedError
    end
  end


  private

  attr_reader :object, :action # needed for exposing to instance_eval'd blocks

  alias_method :record, :record_hash

  def generate_record_hash
    definitions.inject({}) do |hash,(name,definition)|
      hash[name.to_sym] = field_value(name)
      hash
    end
  end

  def method_missing(meth, *args, &block)
    if converters[meth]
      convert(args[0], meth, args[1]||{}) # convert(name, type, options)
    else
      super
    end
  end

end
