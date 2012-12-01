class Object
  def deep_freeze
    instance_variables.each{|v| instance_variable_get(v).freeze }
    freeze
  end
end
