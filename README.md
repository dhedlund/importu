# Importu

[![Gem Version](http://img.shields.io/gem/v/importu.svg)][gem]
[![CI](https://github.com/dhedlund/importu/actions/workflows/ci.yml/badge.svg)][ci]

[gem]: https://rubygems.org/gems/importu
[ci]: https://github.com/dhedlund/importu/actions/workflows/ci.yml

Importu is a declarative data import library for Ruby. Define importers that
read like specifications - with fields, converters, and validation rules -
then parse CSV, JSON, or XML with consistent error handling.

## Table of Contents

- [Goals](#goals)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Example](#example)
- [Sources](#sources) (CSV, JSON, XML, Ruby)
- [Converters](#converters)
- [Backends](#backends) (ActiveRecord)
- [Error Handling](#error-handling)
- [Contributing](#contributing)

For working examples, see the [importu-examples](https://github.com/dhedlund/importu-examples) repository.

## Goals

**Primary goal:** Importers that read like specifications.

- Define fields, converters, and rules declaratively
- Separate what the data should look like from how you process it
- Use the importer as the contract shared with data providers

**Secondary goals:**

- Reusable parsers for common formats (CSV, JSON, XML)
- Modular design - extend or replace components as needed

## Installation

Add to your Gemfile:

```ruby
gem "importu"
```

Then run `bundle install`.

Or install directly:

```bash
gem install importu
```

## Requirements

- Ruby >= 3.1
- Rails >= 7.2 (optional, for ActiveRecord backend)
- nokogiri (optional, for XML source)

## Quick Start

```ruby
require "importu"

# Define an importer with the fields you expect
class BookImporter < Importu::Importer
  fields :title, :author, :isbn10
end

# Create a source and importer
source = Importu::Sources::CSV.new("books.csv")
importer = BookImporter.new(source)

# Iterate over records
importer.records.each do |record|
  puts "#{record[:title]} by #{record[:author]}"
end
```

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

filename = File.expand_path("data.csv", __dir__)
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

## Sources

Importu supports multiple source formats. Each source parses input data and
provides an enumerator of row hashes.

### CSV

```ruby
source = Importu::Sources::CSV.new("data.csv")

# With custom options
source = Importu::Sources::CSV.new("data.csv", csv_options: {
  col_sep: ";",
  encoding: "ISO-8859-1"
})
```

Options inside `csv_options` are passed directly to Ruby's
[CSV library](https://ruby-doc.org/stdlib/libdoc/csv/rdoc/CSV.html).
Common options include `col_sep`, `quote_char`, and `encoding`.

### JSON

```ruby
source = Importu::Sources::JSON.new("data.json")
```

The JSON file must have an array as the root element. The entire file is loaded
into memory, so this source is not suitable for very large files.

### XML

```ruby
# records_xpath is required
source = Importu::Sources::XML.new("data.xml", records_xpath: "//book")
```

The `records_xpath` option specifies which elements to treat as records. Each
matching element becomes a row, with child elements and attributes becoming
fields.

### Ruby

```ruby
data = [
  { "name" => "Alice", "email" => "alice@example.com" },
  { "name" => "Bob", "email" => "bob@example.com" }
]
source = Importu::Sources::Ruby.new(data)
```

Accepts an array of hashes or any enumerable that yields objects responding to
`to_hash`. Useful for importing data already in memory or from other Ruby
sources.


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

Some converters, such as :date and :datetime, accept optional arguments. To
pass arguments to a converter, add them after the converter's type, For
example, `&convert_to(:date, format: "%Y-%m-%d")` will force date parsing to
use the "YYYY-MM-DD" format.

| Type      | Argument | Default      | Description |
|-----------|----------|--------------|-------------|
| :date     | :format  | _autodetect_ | Parse value using a [strftime format](https://ruby-doc.org/stdlib/libdoc/date/rdoc/Date.html#method-i-strftime).
| :datetime | :format  | _autodetect_ | Parse value using a [strftime format](https://ruby-doc.org/stdlib/libdoc/date/rdoc/DateTime.html#method-i-strftime).

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

filename = File.expand_path("data.csv", __dir__)
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

### Allowed Actions

By default, importers only allow creating new records. If you want to update
existing records, you must explicitly allow it:

```ruby
class BookImporter < Importu::Importer
  model "Book"
  allow_actions :create, :update  # Allow both creating and updating

  find_by :isbn10  # Find existing records by ISBN
  # ...
end
```

If an action is not allowed, the record will be marked as invalid with an error
message explaining which action was rejected.

| Configuration | Behavior |
|---------------|----------|
| `allow_actions :create` | Only create new records (default) |
| `allow_actions :update` | Only update existing records |
| `allow_actions :create, :update` | Create new records and update existing ones |

### Finding Existing Records

Use `find_by` to specify which fields identify existing records:

```ruby
class BookImporter < Importu::Importer
  model "Book"
  allow_actions :create, :update

  find_by :isbn10  # Single field
  # or
  find_by :title, :author  # Multiple fields (all must match)
  # or
  find_by do |record|  # Custom lookup logic
    find_by(title: record[:title].downcase)
  end
end
```

### Before Save Hook

Use `before_save` to modify records just before they're saved:

```ruby
class BookImporter < Importu::Importer
  model "Book"

  before_save do
    # `object` is the model instance, `record` is the import data, `action` is :create or :update
    object.title = object.title.titleize
    object.imported_at = Time.current
    object.created_by = "importer" if action == :create
  end
end
```

### Controlling Field Assignment

By default, all fields are assigned on both create and update. You can
control this per-field:

```ruby
class BookImporter < Importu::Importer
  model "Book"
  allow_actions :create, :update

  field :isbn10                        # Assigned on create and update (default)
  field :created_by, update: false     # Only assigned on create
  field :updated_by, create: false     # Only assigned on update
end
```

## Error Handling

### Checking Individual Records

Records can have conversion errors (invalid data types, missing required
fields). Check validity before processing:

```ruby
importer.records.each do |record|
  if record.valid?
    process(record.to_hash)
  else
    record.errors.each { |e| puts e.to_s }
  end
end
```

### Import Summary

When using `import!` with a backend, the returned summary contains aggregate
results and error details:

```ruby
summary = importer.import!

# Aggregate counts
puts "Total: #{summary.total}"
puts "Created: #{summary.created}"
puts "Updated: #{summary.updated}"
puts "Unchanged: #{summary.unchanged}"
puts "Invalid: #{summary.invalid}"

# Human-readable output
puts summary.result_msg

# Machine-readable output (for JSON APIs, etc.)
summary.to_hash
```

### Error Details

```ruby
# Aggregated error counts
summary.validation_errors.each do |message, count|
  puts "#{message}: #{count} occurrences"
end

# Errors by record index (0-based)
summary.itemized_errors.each do |index, errors|
  puts "Record #{index}: #{errors.map(&:to_s).join(', ')}"
end
```

### Generating Error Reports

All file-based sources can generate a copy of the input with errors appended,
useful for returning to data providers:

```ruby
summary = importer.import!

if summary.invalid > 0
  error_file = source.write_errors(summary)
  # error_file is a Tempfile with "_errors" column/field added

  # To include only rows that had errors:
  error_file = source.write_errors(summary, only_errors: true)
end
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

Before submitting changes, run the preflight checks:

```bash
bundle exec rake preflight
```
