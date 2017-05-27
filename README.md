[![Build Status](https://travis-ci.org/tomdalling/rschema.svg?branch=master)](https://travis-ci.org/tomdalling/rschema)
[![Test Coverage](https://codeclimate.com/github/tomdalling/rschema/badges/coverage.svg)](https://codeclimate.com/github/tomdalling/rschema/coverage)

NOTE: These are the docs for the version 3 prerelease
=====================================================

For earlier versions, see the tags.


RSchema
=======

Schema-based validation and coercion for Ruby data structures. Heavily inspired
by [Prismatic/schema](https://github.com/Prismatic/schema).

Meet RSchema
------------

RSchema provides a way to describe, validate, and coerce the "shape" of data.

First you create a schema:

    blog_post_schema = RSchema.define_hash {{
      title: _String,
      tags: array(_Symbol),
      body: _String,
    }}

Then you can use the schema to validate data:

    input = {
      title: "One Weird Trick Developers Don't Want You To Know!",
      tags: [:trick, :developers, :unbeleivable],
      body: '<p>blah blah</p>'
    }
    blog_post_schema.valid?(input) #=> true

What Is A Schema?
-----------------

Schemas are objects that _describe and validate a value_.

The simplest schemas are `Type` schemas, which just check the type of a value.

    schema = RSchema.define { _Integer }
    schema.class #=> RSchema::Schemas::Type

    schema.valid?(1234) #=> true
    schema.valid?('hi') #=> false

Then there are composite schemas, which are schemas composed of subschemas.

Array schemas are composite schemas:

    schema = RSchema.define { array(_Integer) }
    schema.valid?([10, 11, 12])  #=> true
    schema.valid?([10, 11, :hi]) #=> false

And so are hash schemas:

    schema = RSchema.define_hash {{
      fname: _String,
      age: _Integer,
    }}

    schema.valid?({ fname: 'Jane', age: 27 }) #=> true
    schema.valid?({ fname: 'Johnny no age' }) #=> false

Schema objects are composable – they are designed to be combined.
This allows schemas to describe complex, nested data structures.

    schema = RSchema.define_hash {{
      fname: maybe(_String),
      favourite_foods: set(_Symbol),
      children_by_age: variable_hash(_Integer => _String)
    }}

    input = {
      fname: nil,
      favourite_foods: Set[:bacon, :cheese, :onion],
      children_by_age: {
        7 => 'Jenny',
        5 => 'Simon',
      },
    }

    schema.valid?(input) #=> true

RSchema provides many different kinds of schema classes for common tasks, but
you can also write custom schema classes if you need to.


The DSL
-------

Schemas are usually created and composed via a DSL using `RSchema.define`.
Schemas can be created without the DSL, but the DSL is much more succinct.

For example, the following two schemas are identical. `schema1` is created via the
DSL, and `schema2` is created manually.

    schema1 = RSchema.define { array(_Symbol) }

    schema2 = RSchema::Schemas::Convenience.wrap(
      RSchema::Schemas::VariableLengthArray.new(
        RSchema::Schemas::Type.new(Symbol)
      )
    )

You will probably not need to create schemas manually unless you are doing
something advanced.

For a full list of DSL methods, see the API documentation for `RSchema::DSL`.


Errors (When Validation Fails)
------------------------------

When something fails validation, it is often important to know exactly _which
values_ were invalid, and _why_. RSchema provides details about every
failure within a result object.

    schema = RSchema.define do
      array(
        fixed_hash(
          name: _String,
          hair: enum([:red, :brown, :blonde, :black])
        )
      )
    end

    input = [
      { name: 'Dane', hair: :black },
      { name: 'Tom', hair: :brown },
      { name: 'Effie', hair: :blond },
      { name: 'Chris', hair: :red },
    ]

    result = schema.validate(input)

    result.class  #=> RSchema::Result
    result.valid? #=> false
    result.error  #=> { 2 => { :hair => #<RSchema::Error> } }

The error above says that the value `:blond`, which exists at location
`input[2][:hair]`, is not a valid enum member. Looking back at the schema, we
see that there is a typo, and it should be `:blonde` instead of `:blond`.

Error objects contain a lot of information, which can be used to generate
error messages for developers or users.

    error = result.error[2][:hair]
    error.class #=> RSchema::Error

    error.value #=> :blond
    error.symbolic_name #=> :not_a_member
    error.schema #=> #<RSchema::Schemas::Enum ...>
    error.schema.members #=> [:red, :brown, :blonde, :black]
    error.to_s #=> "RSchema::Schemas::Enum/not_a_member"
    error.inspect
      #=> "<RSchema::Error RSchema::Schemas::Enum/not_a_member value=:blond>"


Type Schemas
------------

The most basic kind of schema is a `Type` schema.
Type schemas validate the class of a value using `is_a?`.

    schema = RSchema.define { type(String) }
    schema.valid?('hi') #=> true
    schema.valid?(1234) #=> false

Type schemas are so common that the RSchema DSL provides a shorthand way to
create them, using an underscore prefix:

    schema1 = RSchema.define { _Integer }
    # is exactly the same as
    schema2 = RSchema.define { type(Integer) }

Because type schemas use `is_a?`, they handle subclasses, and can also be used
to check for `include`d modules like `Enumerable`:

    schema = RSchema.define { _Enumerable }
    schema.valid?([1, 2, 3]) #=> true
    schema.valid?({ a: 12 }) #=> true

Variable-length Array Schemas
-----------------------------

There are two types of array schemas.
The first type are `VariableLengthArray` schemas, which check that all elements
in the array conform to a single subschema:

    schema = RSchema.define { array(_Symbol) }

    schema.valid?([:a, :b, :c]) #=> true
    schema.valid?([:a]) #=> true
    schema.valid?([]) #=> true

Fixed-length Array Schemas
--------------------------

There are also `FixedLengthArray` schemas, where the array must have a specific
length, and each element of the array has a separate subschema:

    schema = RSchema.define { array(_Integer, _String) }

    schema.valid?([10, 'hello']) #=> true
    schema.valid?(['heyoo', 33]) #=> false

Fixed Hash Schemas
------------------

There are also two kinds of hash schemas.

`FixedHash` schemas describe hashes where they keys are known constants:

    schema = RSchema.define do
      fixed_hash(
        name: _String,
        age: _Integer,
      )
    end

    schema.valid?({ name: 'George', age: 2 }) #=> true

Elements can be optional:

    schema = RSchema.define do
      fixed_hash(
        name: _String,
        optional(:age) => _Integer,
      )
    end

    schema.valid?({ name: 'Lucy', age: 21 }) #=> true
    schema.valid?({ name: 'Ageless Tommy' }) #=> true

`FixedHash` schemas are common, so the `RSchema.define_hash` method exists
to make their creation more convenient:

    schema = RSchema.define_hash {{
      name: _String,
      optional(:age) => _Integer,
    }}

Variable Hash Schemas
---------------------

`VariableHash` schemas are for hashes where the keys are _not_ known ahead of time.
They contain one subschema for keys, and another subschema for values.

    schema = RSchema.define { variable_hash(_Symbol => _Integer) }
    schema.valid?({}) #=> true
    schema.valid?({ a: 1 }) #=> true
    schema.valid?({ a: 1, b: 2 }) #=> true

Other Schema Types
------------------

RSchema provides a few other schema types through its DSL:

    # boolean (only true or false)
    boolean_schema = RSchema.define { boolean }
    boolean_schema.valid?(true)  #=> true
    boolean_schema.valid?(false) #=> true
    boolean_schema.valid?(nil)   #=> false

    # anything (literally any value)
    anything_schema = RSchema.define { anything }
    anything_schema.valid?('Hi')  #=> true
    anything_schema.valid?(true)  #=> true
    anything_schema.valid?(1234)  #=> true
    anything_schema.valid?(nil)   #=> true

    # either (sum types)
    either_schema = RSchema.define { either(_String, _Integer, _Float) }
    either_schema.valid?('hi') #=> true
    either_schema.valid?(5555) #=> true
    either_schema.valid?(77.2) #=> true

    # maybe (allows nil)
    maybe_schema = RSchema.define { maybe(_Integer) }
    maybe_schema.valid?(5)   #=> true
    maybe_schema.valid?(nil) #=> true

    # enum (a set of valid values)
    enum_schema = RSchema.define { enum([:a, :b, :c]) }
    enum_schema.valid?(:a) #=> true
    enum_schema.valid?(:z) #=> false

    # predicate (block returns true for valid values)
    predicate_schema = RSchema.define do
      predicate { |x| x.even? }
    end
    predicate_schema.valid?(4) #=> true
    predicate_schema.valid?(5) #=> false

    # pipeline (apply multiple schemas to a single value, in order)
    pipeline_schema = RSchema.define do
      pipeline(
        either(_Integer, _Float),
        predicate { |x| x.positive? },
      )
    end
    pipeline_schema.valid?(123) #=> true
    pipeline_schema.valid?(5.1) #=> true
    pipeline_schema.valid?(-24) #=> false

For a full list of built-in schema types, see the API documentation for all
classes in the `RSchema::Schemas` module.

Extending The DSL
-----------------

To add methods to the default DSL, first create a module:

    module MyCustomMethods
      def palendrome
        pipeline(
          _String,
          predicate { |s| s == s.reverse },
        )
      end
    end

Then include your module into `RSchema::DefaultDSL`:

    RSchema::DefaultDSL.include(MyCustomMethods)

And your methods will be available via `RSchema.define`:

    schema = RSchema.define { palendrome }

    schema.valid?('racecar') #=> true
    schema.valid?('ferrari') #=> false

This is the preferred way for you, and other gems, to extend RSchema with new
DSL methods.

Creating Your Own DSL
---------------------

The default DSL is designed to be extended (i.e. modified) by you, and
third-party gems. If you want a DSL that isn't affected by external factors,
you can create one yourself.

Create a new class, and include `RSchema::DSL` if you want have all the
standard DSL methods that come built-in to RSchema. You can define your own
custom methods on this class.

    class MyCustomDSL
      include RSchema::DSL # this is optional

      def palendrome
        pipeline(
          _String,
          predicate { |s| s == s.reverse },
        )
      end
    end

Then pass an instance of your DSL class into `RSchema.define`:

    dsl = MyCustomDSL.new
    schema = RSchema.define(dsl) { palendrome }
    schema.valid?('racecar') #=> true

Coercion
--------

Coercers convert invalid data into valid data where possible, according to a
schema.

Take HTTP params as an example. Web forms often contain database IDs, which
are integers, but are submitted as strings by the browser. Param hash keys
are often expected to be `Symbol`s, but are also strings. RSchema can
automatically convert these strings into the appropriate type, based on a
schema.

    # Input keys and values are all strings
    input_params = {
      'whatever_id' => '5',
      'amount' => '123.45',
    }

    # The schema expects symbol keys, an integer value, and a float value
    schema = RSchema.define_hash {{
      whatever_id: _Integer,
      amount: _Float,
    }}

    # A coercer is created by wrapping the schema
    coercer = RSchema::CoercionWrapper::RACK_PARAMS.wrap(schema)

    # Use the coercer like a normal schema object
    result = coercer.validate(input_params)

    # The result object contains the coerced value
    result.valid? #=> true
    result.value #=> { :whatever_id => 5, :amount => 123.45 }

Custom Coercion
---------------

Coercion is designed to be totally extensible. You'll have to take my word
for it, because there isn't much documentation at the moment.

See `lib/rschema/coercion_wrapper/rack_params.rb` for an example of how to
make a coercion wrapper.

See all the classes in `lib/rschema/coercers/` for examples of how to make
individual coercers.

If you have any problems or questions about implementing custom coercion, feel
free to contact me (Tom Dalling).


Implementing Your Own Schema Types
----------------------------------

Schemas are objects that conform to a certain interface (i.e. a duck type).
To create your own schema types, you just need to implement this interface.

The interface consists of two methods: `call` and `with_wrapped_subschemas`.
The `call` method is the interface for validating values.
The `with_wrapped_subschemas` is necessary for coercion to work.
If you have any problems or questions regarding this schema interface, feel
free to contact me (Tom Dalling).

Below is a custom schema for pairs – arrays with two elements of the same type.
This is already possible using existing schemas (e.g. `array(_String, _String)`),
and is only shown here for the purpose of demonstration.

    class PairSchema
      def initialize(subschema)
        @subschema = subschema
      end

      #
      # This method is mandatory.
      #
      # `pair` is the value to validate.
      # `options` is an `RSchema::Options` object.
      # This method must return a `RSchema::Result` object
      #
      def call(pair, options)
        return not_an_array_failure(pair) unless pair.is_a?(Array)
        return not_a_pair_failure(pair) unless pair.size == 2

        # pass both array elements to `@subschema.call`
        subresults = pair.map { |x| @subschema.call(x, options) }

        # check if both elements are valid according to @subschema
        if subresults.all?(&:valid?)
          RSchema::Result.success(subresults.map(&:value))
        else
          RSchema::Result.failure(subschema_error(subresults))
        end
      end

      #
      # This method is necessary for coercion to work
      #
      def with_wrapped_subschemas(wrapper)
        PairSchema.new(wrapper.wrap(@subschema))
      end

      private

        def not_an_array_failure(pair)
          RSchema::Result.failure(
            RSchema::Error.new(
              symbolic_name: :not_an_array,
              schema: self,
              value: pair,
            )
          )
        end

        def not_a_pair_failure(pair)
          RSchema::Result.failure(
            RSchema::Error.new(
              symbolic_name: :not_a_pair,
              schema: self,
              value: pair,
            )
          )
        end

        #
        # Returns a hash of index => error
        #
        def subschema_error(subresults)
          subresults
            .each_with_index
            .select { |(result, idx)| result.invalid? }
            .map { |(result, idx)| [idx, result.error] }
            .to_h
        end
    end

Add your new schema class to the default DSL:

    module PairSchemaDSL
      def pair(subschema)
        PairSchema.new(subschema)
      end
    end

    RSchema::DefaultDSL.include(PairSchemaDSL)

Then your schema is accessible from `RSchema.define`:

    gps_coordinate_schema = RSchema.define { pair(_Float) }
    gps_coordinate_schema.valid?([1.2, 3.4]) #=> true

Coercion should work, as long as `#with_wrapped_subschemas` was implemented
correctly.

    coercer = RSchema::CoercionWrapper::RACK_PARAMS.wrap(gps_coordinate_schema)
    result = coercer.validate(["1", "2"])
    result.valid? #=> true
    result.value #=> [1.0, 2.0]

