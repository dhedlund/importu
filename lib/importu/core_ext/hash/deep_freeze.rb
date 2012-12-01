class Hash
  def deep_freeze
    return self if frozen?
    values.each(&:deep_freeze)
    freeze
  end
end
