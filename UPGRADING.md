# Upgrading to Importu 0.2.0

This guide covers breaking changes when upgrading from 0.1.0 to 0.2.0.

## Prerequisites

Before upgrading, ensure your environment meets the new requirements:

- **Ruby >= 3.1** (was 2.3+)
- **Rails >= 7.2** if using ActiveRecord backend (was 4.x+)
- **nokogiri >= 1.18.4** (security requirement)

## Step 1: Update Exception Handling

The JSON source now uses Ruby's stdlib JSON instead of MultiJson.

```ruby
# Before (0.1.0)
rescue MultiJson::DecodeError => e
  # handle JSON parse error

# After (0.2.0)
rescue JSON::ParserError => e
  # handle JSON parse error
```

## Step 2: Update Require Statements

The main entry point now eager-loads all components.

```ruby
# Before (0.1.0) - explicit requires needed
require "importu"
require "importu/importer"
require "importu/sources/csv"

# After (0.2.0) - single require loads everything
require "importu"
# Importer class and all sources are now available
```

**Note:** If you have custom autoloading or deferred requires, the eager
loading may affect initialization order.

## Step 3: Update Custom Exception Handling

### InvalidRecord

The constructor now accepts a `normalized_message:` keyword argument for
better error aggregation:

```ruby
# Before (0.1.0)
raise Importu::InvalidRecord.new("error message", validation_errors)

# After (0.2.0) - still works, but you can optionally add:
raise Importu::InvalidRecord.new(
  "field is invalid (row 5)",
  validation_errors,
  normalized_message: "field is invalid"  # Used for aggregation
)
```

The `normalized_message` is used by `Summary#validation_errors` to group
similar errors together. If not provided, the summary strips trailing
parenthesized data automatically.

### MissingField

The constructor now uses a keyword argument for `available_fields`:

```ruby
# Before (0.1.0) - if you raised this manually
raise Importu::MissingField.new(definition, available_fields)

# After (0.2.0)
raise Importu::MissingField.new(definition, available_fields: available_fields)
```

## Step 4: Update Error Message Parsing

### Summary#validation_errors Format

Error messages are now normalized before aggregation. Trailing parenthesized
data (like row numbers) is stripped:

```ruby
# Before (0.1.0) - errors kept exact messages
summary.validation_errors
# => { "name is invalid (row 5)" => 1, "name is invalid (row 12)" => 1 }

# After (0.2.0) - messages are normalized for aggregation
summary.validation_errors
# => { "name is invalid" => 2 }
```

**If you need exact error messages**, use `itemized_errors` instead:

```ruby
summary.itemized_errors.each do |index, errors|
  errors.each { |e| puts "Row #{index}: #{e.to_s}" }
end
```

### Rails 7+ Error Format

The ActiveRecord backend now uses the Rails 7+ errors API:

```ruby
# Error messages now formatted as:
"attribute message"  # e.g., "title can't be blank"

# Instead of Rails 6 style:
"Attribute message"  # e.g., "Title can't be blank"
```

This affects how errors appear in `Summary#validation_errors`.

## Step 5: Update Source Usage

### File Handle Management

Sources now have a `close` method. For long-running processes, explicitly
close sources when done:

```ruby
source = Importu::Sources::CSV.new("data.csv")
importer = MyImporter.new(source)
summary = importer.import!
source.close  # New in 0.2.0
```

The JSON source closes its file handle immediately after reading (since it
loads everything into memory), so `close` is a no-op for JSON.

### Removed: xml_options Parameter

The `xml_options` parameter was removed from `Importu::Sources::XML` as it
was never implemented:

```ruby
# Before (0.1.0) - accepted but ignored
source = Importu::Sources::XML.new("data.xml",
  records_xpath: "//book",
  xml_options: { encoding: "UTF-8" }  # This never did anything
)

# After (0.2.0) - parameter removed
source = Importu::Sources::XML.new("data.xml", records_xpath: "//book")
```

### Removed: allow_sources DSL

The `allow_sources` DSL method was removed as it was never enforced:

```ruby
# Before (0.1.0) - accepted but never checked
class MyImporter < Importu::Importer
  allow_sources :csv, :json  # This never did anything
end

# After (0.2.0) - method removed
# Simply don't use it; pass the correct source type when creating the importer
```

## Step 6: Test Your Import Code

After upgrading, verify your imports work correctly:

1. Run your test suite
2. Test with sample data files
3. Check error handling paths
4. Verify error message formatting meets your needs

## Summary of Breaking Changes

| Change | Impact | Action Required |
|--------|--------|-----------------|
| Ruby >= 3.1 | High | Upgrade Ruby |
| Rails >= 7.2 | High | Upgrade Rails (if using AR backend) |
| MultiJson removed | Medium | Change exception handling |
| Require path changed | Low | Simplify requires |
| Error normalization | Low | Update error parsing if needed |
| `normalized_message` added | Low | None (backwards compatible) |
| `available_fields:` keyword | Low | Update if raising MissingField |
| `xml_options` removed | Low | Remove if passing |
| `allow_sources` removed | Low | Remove if using |
| `close` method added | Low | Call for long-running processes |
