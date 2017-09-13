Contains the original three records from the "books-valid" fixture, along with
three additional records that share the same isbn10 value as valid records. The
additional records are valid, but they appear in the same source file as other
records sharing the same `find_by` key. Because they share the same values used
to find the object, they will find an object with the same :id used earlier in
the import. If an object's id matches an id used earlier in the import, the
record is considered to be a duplicate.
