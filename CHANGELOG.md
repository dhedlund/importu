# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking Changes

- Add csv and bigdecimal as gem dependencies (no longer default gems in Ruby 3.4+)
- Replace multi_json with stdlib json (JSON::ParserError instead of MultiJson::DecodeError)

### Fixed

- Remove phantom require for nonexistent backends/ruby file
- Add explicit require for delegate stdlib
- Add explicit require for date stdlib
- Fix ConverterStub to properly initialize Proc superclass
- Fix keyword argument splatting throughout codebase
- Fix CSV source to create fresh reader on each rows call
- Fix JSON source to handle empty documents

## [0.1.0] - 2017-09-25

Initial release.
