## Overview

Importu is a framework and DSL for simplifying the process of importing
structured data into your application.  It is also a tool for separating
import-related business logic from the rest of your code.


## Example

Assuming you have the following data in the file `data.csv`:
```
"isbn10","title","author","release_date","pages"
"0596516177","The Ruby Programming Language","David Flanagan and Yukihiro Matsumoto","Feb 1, 2008","448"
"1449355978","Computer Science Programming Basics in Ruby","Ophir Frieder, Gideon Frieder and David Grossman","May 1, 2013","188"
"0596523696","Ruby Cookbook"," Lucas Carlson and Leonard Richardson","Jul 26, 2006","910"
```

You can create a minimal importer to read the CSV data:
```ruby
class BookImporter < Importu::Importer
  # fields we expect to find in the CSV file, field order is not important
  fields :title, :author, :isbn10, :pages, :release_date
end
```

And then load that data in your application:
```ruby
require "importu"

filename = File.expand_path("../data.csv", __FILE__)
importer = BookImporter.new(Importu::Sources::CSV.new(filename))

# importer.records returns an Enumerable
importer.records.count # => 3
importer.records.select {|r| r[:author] =~ /Matsumoto/ }.count # => 1
importer.records.each do |record|
  # ...
end

importer.records.map(&:to_hash)
```

A more complete example of the book importer above might look like the following:
```ruby
require "importu"

class BookImporter < Importu::Importer
  # if you want to define multiple fields with similar rules, use "fields"
  # NOTE: `required: true` is redundant in this example; any defined
  # fields must have a corresponding column in the source data by default
  fields :title, :isbn10, :authors, required: true

  # to mark a field as optional in the source data
  field :pages, required: false

  # you can reference the same field multiple times and apply rules
  # incrementally; this provides a lot of flexibility in describing your
  # importer rules, such as grouping all the required fields together and
  # explicitly stating that "these are required"; the importer becomes the
  # reference document:
  #
  # fields :title, :isbn10, :authors, :release_date, required: true
  # fields :pages, required: false
  #
  # ...or keep all the rules for that field with that field, whatever makes
  # sense for your particular use case.

  # if your field is not named the same as the source data, you can use
  # `label: "..."` to reference the correct field, where the label is what
  # the field is labelled in the source data
  field :authors, label: "author"

  # you can convert fields using one of the built-in converters
  field :pages, &convert_to(:integer)
  field :release_date, &convert_to(:date) # date format is guessed

  # some converters allow you to pass additional arguments; in the case of
  # the date converter, you can pass an explicit format and it will raise an
  # error if a date is encountered that doesn't match
  field :release_date, &convert_to(:date, format: "%b %d, %Y")

  # passing a block to a field definition allows you to add your own logic
  # for converting data or checking for unexpected values
  field :authors do
    value = trimmed(:authors) # apply :trimmed converter which strips whitespace
    authors = value ? value.split(/(?:, )|(?: and )|(?: & )/i) : []

    if authors.none?
      # ArgumentError will be converted to an Importu::FieldParseError, which
      # will include the name of the field affected
      raise ArgumentError, "at least one author is required"
    end

    authors
  end

  # abstract fields that are not part of the original data set can be created
  field :by_matz, abstract: true do
    # field conversion rules can reference other fields; the field value is
    # what would be returned after referenced field's rules have been applied
    field_value(:authors).include?("Yukihiro Matsumoto")
  end
end
```

A more condensed version of the above, with all the rules grouped into individual field definitions:
```ruby
class BookImporter < Importu::Importer
  fields :title, :isbn10

  field :authors, label: "author" do
    authors = trimmed(:authors).to_s.split(/(?:, )|(?: and )|(?: & )/i)
    raise ArgumentError, "at least one author is required" if authors.none?

    authors
  end

  field :pages, required: false, &convert_to(:integer)
  field :release_date, &convert_to(:date, format: "%b %d, %Y")

  field :by_matz, abstract: true do
    field_value(:authors).include?("Yukihiro Matsumoto")
  end
end
```

## Converters

### Built-in Converters

Importu comes with several built-in converters for the most common ruby
data types and data cleanup operations. Assigning a converter to your fields
ensures that the value can be translated to the desired type or a validation
error will be generated and the record flagged as invalid.

To use a converter, add `&convert_to(type)` to the end of a field definition,
where `type` is one of the types below.

| Type      | Description |
|-----------|-------------|
| :boolean  | Coerces value to a boolean. Must be true, yes, 1, false, no, 0. Case-insensitive. |
| :date     | Coerces value to a date. Tries to guess format unless `format: ...` is provided. |
| :datetime | Coerces value to a datetime. Tries to guess format unless `format: ...` is provided. |
| :decimal  | Coerces value to a BigDecimal. |
| :float    | Coerces value to a Float. |
| :integer  | Coerces value to an integer. Must look like an integer ("1.0" is invalid). |
| :raw      | Do nothing. Value will be passed through as-is from the source value. |
| :string   | Coerces value to a string, trimming leading a trailing whitespaces. |
| :trimmed  | Trims leading and trailing whitespace if value is a string, otherwise leave as-is. Empty strings are converted to nil. |

Built-in converters can be overridden by creating a custom converter using
the same name as the built-in converter. Overriding a converter in one import
definition will not affect any converters outside of that definition.

### Custom Converters

All built-in converters are defined using the same method as custom
converters. See `lib/importu/converters.rb` for their implementation, which
can be used as a guide for writing your own.

```ruby
class BookImporter < Importu::Importer
  converter :varchar do |field_name, length: 255|
    value = trimmed(field_name)
    value.nil? ? nil : String(value).slice(0, length)

    # Instead of taking the first 255 characters, you may prefer to raise
    # an error that enforces values from source data cannot exceed length.
    # raise ArgumentError, "cannot exceed "#{length}" if value.length > length
  end

  fields :title, :author, &convert_to(:varchar)
  fields :title, &convert_to(:varchar, length: 50)
end
```

To raise an error from within a converter, raise an `ArgumentError` with a
message. That field will then be marked as invalid on the record and the
message will be used as the validation error message.

If you would like to use the same custom converters across multiple import
definitions, they can be defined in a mixin and then included at the top of
each definition or in a class that the imports inherit from. Importu takes
this approach with its default converters, so you can look at the built-in
converters as an example.

### Default Converter

By default, importu uses the `:trimmed` converter unless a converter has been
explicitly defined for the field. This should work for the vast majority of use
cases, but there are some cases where the default isn't exactly what you
wanted.

1. If you have a couple fields that cannot have their values trimmed, consider
changing those fields to use the :raw converter.

2. If your opinion of trimmed is different than importu's, you can override the
built-in :trimmed converter to match your preferred behavior.

3. If you never want any fields to have the :trimmed converter applied, you can
change the default converter to use the :raw converter:
```ruby
class BookImporter < Importu::Importer
  converter :default, &convert_to(:raw)
end
```

4. If you want to raise an error if a converter is not explicitly set for each
field:
```ruby
class BookImporter < Importu::Importer
  converter :default do |name|
    raise ArgumentError, "converter not defined for field #{name}"
  end
end
```


## Backends

### Rails / ActiveRecord

If you define a model in the importer definition and the importer fields are
named the same as the attributes in your model, Importu can iterate through and
create or update records for you:

```ruby
class BookImporter < Importu::Importer
  model "Book"

  # ...
end

filename = File.expand_path("../data.csv", __FILE__)
importer = BookImporter.new(Importu::Sources::CSV.new(filename))

summary = importer.import!

summary.total # => 3
summary.invalid # => 0
summary.created # => 3
summary.updated # => 0
summary.unchanged # => 0

summary = importer.import!

summary.total # => 3
summary.created # => 0
summary.unchanged # => 3
```

## Development

Importu uses the [appraisal](https://github.com/thoughtbot/appraisal) gem to
test against multiple frameworks and versions. To run the entire test suite:

```bash
bundle exec appraisal bundle exec rspec spec
```

If any changes are made to the `importu.gemspec`, `Gemfile` or `Appraisals`
file, you should re-run the following command to update appraisal generated
under the `gemfiles/` directory:

```bash
bundle exec appraisal install
```
