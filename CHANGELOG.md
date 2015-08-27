# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.1.1](https://github.com/tomdalling/rschema/compare/v1.1.0...v1.1.1) -- 2015-08-27
Fixed:
- Specified minimum Ruby version in gemspec

## [1.1.0](https://github.com/tomdalling/rschema/compare/v1.0.1...v1.1.0) -- 2015-02-28
Added:
- Ability to create custom DSLs (instead of just polluting the default one)

Fixed:
- Minor improvement to enum validation failure message

## [1.0.1](https://github.com/tomdalling/rschema/compare/v1.0.0...v1.0.1) -- 2015-02-26
Fixed:
- Coercion was stripping optional keys from Hash objects. It now leaves
  optional keys in the Hash.

## [1.0.0](https://github.com/tomdalling/rschema/compare/v0.2.0...v1.0.0) -- 2015-02-19
Added:
- Non-throwing `RSchema.validate` method

Changed:
- The `RSchema::ErrorDetails` class has been improved to be more
  human-readable, and also machine-readable.

## 0.2.0 -- 2015-02-12
Added:
- New `BooleanSchema` class with `boolean` DSL method

Changed:
- Slightly better validation failure reasons

