class Array
  def deep_freeze
    return self if frozen?
    each(&:deep_freeze)
    freeze
  end
end
