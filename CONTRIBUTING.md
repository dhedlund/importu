# Contributing to Importu

## Development Setup

```bash
git clone https://github.com/dhedlund/importu.git
cd importu
bundle install
bundle exec appraisal install
```

## Running Tests

```bash
# Run all tests across all Rails versions
bundle exec appraisal rspec

# Run without Rails (standalone)
bundle exec appraisal standalone rspec

# Run against a specific Rails version
bundle exec appraisal rails-8-1 rspec

# Check code style
bundle exec rubocop

# Check documentation coverage
bundle exec rake yardstick
```

## Code Style

RuboCop is configured to match the existing codebase patterns. Run it before
submitting:

```bash
bundle exec rubocop
```

When in doubt, match the style of surrounding code.

## Pull Requests

Before submitting a PR:

1. Ensure all tests pass across all appraisals
2. Ensure RuboCop passes
3. Add tests for new functionality
4. Update CHANGELOG.md under `[Unreleased]` for user-facing changes

## Architecture Overview

The codebase is organized around a few core concepts:

- **Sources** (`lib/importu/sources/`) - Parse input formats (CSV, JSON, XML, Ruby hashes). Each source provides a `rows` enumerator.

- **Backends** (`lib/importu/backends/`) - Persist records to a data store. The ActiveRecord backend is included; others can be added.

- **Middleware** (`lib/importu/backends/middleware/`) - Wrap backends to add cross-cutting behavior like duplicate detection and action enforcement.

- **Converters** (`lib/importu/converters.rb`) - Transform raw field values into typed data. Built-in converters handle strings, integers, dates, booleans, etc.

- **Summary** (`lib/importu/summary.rb`) - Aggregates import results (created, updated, invalid counts and error details).

The importer DSL (`lib/importu/config_dsl.rb`) ties these together, letting you declare fields, converters, and backend configuration in a readable format.

## Adding a New Source

Implement a class with:
- `initialize(infile, **options)` - Accept input and source-specific options
- `rows` - Return an enumerator yielding hashes (one per record)

See `lib/importu/sources/csv.rb` for an example.

## Adding a New Backend

Implement a class with:
- `self.supported_by_model?(model)` - Return true if this backend handles the model
- `initialize(model:, finder_fields:, **options)` - Accept configuration
- `find(record)` - Look up existing record, return nil if not found
- `create(record)` - Create new record, return `[status, object]`
- `update(record, object)` - Update existing record, return `[status, object]`

Register it with `Importu::Backends.registry.register(:name, YourBackend)`.

See `lib/importu/backends/active_record.rb` for an example.
