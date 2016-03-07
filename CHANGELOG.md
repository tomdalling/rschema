# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.4.0](https://github.com/tomdalling/rschema/compare/v1.3.0...v1.4.0) -- 2016-03-07
Added:
- Coercion "true" and "false" strings for BooleanSchema
- Error messages from EnumSchema are more descriptive

## [1.3.0](https://github.com/tomdalling/rschema/compare/v1.2.0...v1.3.0) -- 2015-10-31
Added:
- The `either` schema, which will match any one of a given list of schemas.
- Nicer `inspect` strings for (most) schema types

## [1.2.0](https://github.com/tomdalling/rschema/compare/v1.1.1...v1.2.0) -- 2015-10-29
Added:
- The `any` schema, which matches literally any value.
- The `optional` method to the schema DSL. It functions identically to the `_?` method
  for specifying optional hash keys, except it's a bit more verbose.

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

