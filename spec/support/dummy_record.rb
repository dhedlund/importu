class Importu::Record::Dummy < Importu::Record
  def assign_to(object, action, &block)
    object
  end

  def save!
    :unchanged
  end

end
