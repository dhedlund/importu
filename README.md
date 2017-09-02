## Overview
Importu is a framework and DSL for simplifying the process of importing
structured data into your application.  It is also a tool for separating
import-related business logic from the rest of your code.

Current supported source formats include CSV/TSV, XML and JSON.  It is fairly
trivial to extend Importu to handle additional formats.  See the
`lib/importu/importer` directory for implementations of supported importers.

## Example
**Please read the tutorial in the
[import-examples](https://github.com/dhedlund/importu-examples) repository for
a more complete overview of available features.**

Assuming you have the following data in the file `data.csv`:
```
"isbn10","title","author","release_date","pages"
"0596516177","The Ruby Programming Language","David Flanagan and Yukihiro Matsumoto","Feb 1, 2008","448"
"1449355978","Computer Science Programming Basics in Ruby","Ophir Frieder, Gideon Frieder and David Grossman","May 1, 2013","188"
"0596523696","Ruby Cookbook"," Lucas Carlson and Leonard Richardson","Jul 26, 2006","910"
```

You can create a minimal importer to read the CSV data:
```ruby
class BookImporter < Importu::Importer::Csv
  # fields we expect to find in the CSV file, field order is not important
  fields :title, :author, :isbn10, :pages, :release_date
end
```

And then load that data in your application:
```ruby
require "importu"

filename = File.expand_path("../data.csv", __FILE__)
importer = BookImporter.new(filename)

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

class BookImporter < Importu::Importer::Csv
  # if you want to define multiple fields with similar rules, use "fields"
  # NOTE: ":required => true" is redundant in this example; any defined
  # fields must have a corresponding column in the source data by default
  fields :title, :isbn10, :authors, :required => true

  # to mark a field as optional in the source data
  field :pages, :required => false

  # you can reference the same field multiple times and apply rules
  # incrementally; this provides a lot of flexibility in describing your
  # importer rules, such as grouping all the required fields together and
  # explicitly stating that "these are required"; the importer becomes the
  # reference document:
  #
  # fields :title, :isbn10, :authors, :release_date, :required => true
  # fields :pages, :required => false
  #
  # ...or keep all the rules for that field with that field, whatever makes
  # sense for your particular use case.

  # if your field is not named the same as the source data, you can use
  # :label => "..." to reference the correct field, where the label is what
  # the field is labelled in the source data
  field :authors, :label => "author"

  # you can convert fields using one of the built-in converters
  field :pages, &convert_to(:integer)
  field :release_date, &convert_to(:date) # date format is guessed

  # some converters allow you to pass additional arguments; in the case of
  # the date converter, you can pass an explicit format and it will raise an
  # error if a date is encountered that doesn't match
  field :release_date, &convert_to(:date, :format => "%b %d, %Y")

  # passing a block to a field definition allows you to add your own logic
  # for converting data or checking for unexpected values
  field :authors do
    value = clean(:authors) # apply :clean converter which strips whitespace
    authors = value ? value.split(/(?:, )|(?: and )|(?: & )/i) : []

    if authors.none?
      # ArgumentError will be converted to an Importu::FieldParseError, which
      # will include the name of the field affected
      raise ArgumentError, "at least one author is required"
    end

    authors
  end

  # abstract fields that are not part of the original data set can be created
  field :by_matz, :abstract => true do
    # field conversion rules can reference other fields; the field value is
    # what would be returned after referenced field's rules have been applied
    field_value(:authors).include?("Yukihiro Matsumoto")
  end
end
```

A more condensed version of the above, with all the rules grouped into individual field definitions:
```ruby
class BookImporter < Importu::Importer::Csv
  fields :title, :isbn10

  field :authors, :label => "author" do
    authors = clean(:authors).to_s.split(/(?:, )|(?: and )|(?: & )/i)
    raise ArgumentError, "at least one author is required" if authors.none?

    authors
  end

  field :pages, :required => false, &convert_to(:integer)
  field :release_date, &convert_to(:date, :format => "%b %d, %Y")

  field :by_matz, :abstract => true do
    field_value(:authors).include?("Yukihiro Matsumoto")
  end
end
```

### Rails / ActiveRecord
If you define a model in the importer definition and the importer fields are
named the same as the attributes in your model, Importu can iterate through and
create or update records for you:

```ruby
class BookImporter < Importu::Importer::Csv
  model "Book"

  # ...
end

filename = File.expand_path("../data.csv", __FILE__)
importer = BookImporter.new(filename)

importer.import!

importer.total # => 3
importer.invalid # => 0
importer.created # => 3
importer.updated # => 0
importer.unchanged # => 0

importer.import!

importer.total # => 3
importer.created # => 0
importer.unchanged # => 3
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
