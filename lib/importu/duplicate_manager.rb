require "set"

require "importu/exceptions"

# The duplicate manager provides support for recording records and objects
# encountered during the import process. When records or objects have been
# encountered previously, a Importu::DuplicateRecord exception is raised.
class Importu::DuplicateManager

  # Creates a new instance of the duplicate manager.
  #
  # @example
  #   manager = Importu::DuplicateManager.new
  #
  # @param finder_fields [Array<Array<Symbol>>] A list of finder field
  #   groups that should be used when checking if records are duplicates.
  # @return [Importu::DuplicateManager]
  #
  # @api public
  def initialize(finder_fields: [])
    # Proc-based finder fields cannot be directly applied to records, as
    # it requires looking up the corresponding object using the backend.
    @finder_fields = finder_fields.reject {|fg| fg.respond_to?(:call) }

    @encountered = Set.new
  end

  # Checks that the unique id of an object returned from the backend has not
  # been encountered before. Raises a DuplicateError exception if the object
  # has been encountered before, otherwise the object is marked as seen.
  #
  # @example
  #   manager.check_object!(71)
  #   manager.check_object!("0aefe55a-58bb-4a16-b873-ba3425e443bb")
  #   manager.check_object!(71) # raises Importu::DuplicateManager
  #
  # @param unique_id [#eql, #hash] A unique object identifier that can be
  #   compared against other object identifiers.
  # @return [void]
  # @raise [Importu::DuplicateRecord]
  #
  # @api public
  def check_object!(unique_id)
    return unless unique_id

    result = @encountered.add?(_object_unique_id: unique_id)
    duplicate_record! if result.nil?
  end

  # Checks that a conflicting record has not been encountered before. Uses
  # the configured finder_fields to construct sets of key/value pairs that
  # are considered unique enough to look up objects from the backend. Marks
  # all of the key/value pairs as encountered if not seen before. Raises a
  # DuplicateError exception if any were previously encountered.
  #
  # @example
  #   manager.check_record!(record)
  #   manager.check_record!(record) # raises Importu::DuplicateRecord
  #
  # @param record [Importu::Record]
  # @return [void]
  # @raise [Importu::DuplicateRecord]
  #
  # @api public
  def check_record!(record)
    results = @finder_fields.map do |field_group|
      begin
        conditions = Hash[field_group.map {|f| [f, record.fetch(f)] }]
        @encountered.add?(conditions) ? :added : :duplicate
      rescue KeyError
        # Field group key not defined on record, always nil so invalid
        :skipped
      end
    end

    duplicate_record! if results.include?(:duplicate)
  end

  # Raises an Importu::DuplicateRecord exception
  #
  # @return [void] never returns
  # @raise [Importu::DuplicateRecord]
  #
  # @api private
  private def duplicate_record!
    raise Importu::DuplicateRecord, "matches a previous record"
  end

end
