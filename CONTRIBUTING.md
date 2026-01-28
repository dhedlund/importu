# Contributing to Importu

## Development Setup

```bash
git clone https://github.com/dhedlund/importu.git
cd importu
bundle install
bundle exec appraisal install
```

## Running Checks

The preflight task runs specs, RuboCop, and YARD coverage in one command:

```bash
bundle exec rake preflight
```

To run checks individually:

```bash
bundle exec rspec              # Test suite (standalone, no Rails)
bundle exec rubocop            # Code style
bundle exec rake yardstick     # Documentation coverage
```

To test against specific Rails versions:

```bash
bundle exec appraisal rspec              # All Rails versions
bundle exec appraisal standalone rspec   # No Rails
bundle exec appraisal rails-8-1 rspec    # Specific version
```

## Pull Requests

Before submitting a PR, run the preflight checks:

```bash
bundle exec rake preflight
```

This runs the test suite, RuboCop, and YARD coverage verification.

Also:

1. Add tests for new functionality
2. Update CHANGELOG.md under `[Unreleased]` for user-facing changes

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
