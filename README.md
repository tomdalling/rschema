[![Build Status](https://travis-ci.org/tomdalling/rschema.svg?branch=master)](https://travis-ci.org/tomdalling/rschema)
[![Test Coverage](https://codeclimate.com/github/tomdalling/rschema/badges/coverage.svg)](https://codeclimate.com/github/tomdalling/rschema/coverage)

RSchema
=======

Schema-based validation and coercion for Ruby data structures. Heavily inspired
by [Prismatic/schema][].

Meet RSchema
------------

RSchema provides a way to describe, validate, and coerce the "shape" of data.

First you create a schema:

```ruby
blog_post_schema = RSchema.define_hash {{
  title: _String,
  tags: Array(_Symbol),
  body: _String,
}}
```

Then you can use the schema to validate data:

```ruby
input = {
  title: "One Weird Trick Developers Don't Want You To Know!",
  tags: [:trick, :developers, :unbeleivable],
  body: '<p>blah blah</p>'
}
blog_post_schema.call(input).valid? #=> true
```

What Is A Schema?
-----------------

Schemas are objects that _describe and validate a values_.

The simplest schemas are `Type` schemas, which just validate the type of a value.

```ruby
schema = RSchema.define { _Integer }
schema.class #=> RSchema::Schemas::Type

schema.call(1234).valid? #=> true
schema.call('hi').valid? #=> false
```

Then there are composite schemas, which are schemas composed of subschemas.

Arrays are composite schemas:

```ruby
schema = RSchema.define { Array(_Integer) }
schema.call([10, 11, 12]).valid?  #=> true
schema.call([10, 11, :hi]).valid? #=> false
```

And so are hashes:

```ruby
schema = RSchema.define do
  Hash(fname: _String, age: _Integer)
end

schema.call({ fname: 'Jane', age: 27 }).valid? #=> true
schema.call({ fname: 'Johnny' }).valid? #=> false
```

Schema objects are composable – they are designed to be combined.
This allows schemas to describe complex, nested data structures.

```ruby
schema = RSchema.define_hash {{
  fname: predicate { |n| n.is_a?(String) && n.size > 0 },
  favourite_foods: Set(_Symbol),
  children_by_age: VariableHash(_Integer => _String)
}}

input = {
  fname: 'Johnny',
  favourite_foods: Set.new([:bacon, :cheese, :onion]),
  children_by_age: {
    7 => 'Jenny',
    5 => 'Simon',
  },
}

schema.call(input).valid? #=> true
```

RSchema provides many different kinds of schema classes for common tasks, but
you can also write custom schema classes if you need to.


The DSL
-------

Schemas are usually created and composed via a DSL using `RSchema.define`.
They can be created manually, although this is often too verbose.

For example, the following two schemas are identical. `schema1` is created via the
DSL, and `schema2` is created manually.

```ruby
schema1 = RSchema.define { Array(_Symbol) }

schema2 = RSchema::Schemas::VariableArray.new(
  RSchema::Schemas::Type.new(Symbol)
)
```

You will probably never need to create schemas manually unless you are doing
something advanced, like writing your own DSL.

The DSL is designed to be extensible. You can add your own methods to the
default DSL, or create a separate, custom DSL to suite your needs.


When Validation Fails
---------------------

When data fails validation, it is often important to know exactly _which
values_ were invalid, and _why_. RSchema provides details about every
failure within a result object.

```ruby
schema = RSchema.define do
  Array(
    Hash(
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

result = schema.call(input)

result.class #=> RSchema::Result
result.valid? #=> false
result.error #=> { 2 => { :hair => #<RSchema::Error> } }
result.error[2][:hair].to_s
  #=> "Error RSchema::Schemas::Enum/not_a_member for value: :blond"
```

The error above says that the value `:blond`, which exists at location
`input[2][:hair]`, is not a valid enum member. Looking back at the schema, we
see that there is a typo, and it should be `:blonde` instead of `:blond`.

Error objects contain a lot of information, which can be used to generate
error messages for developers or users.

```ruby
error = result.error[2][:hair]
error.class #=> RSchema::Error

error.value #=> :blond
error.symbolic_name #=> :not_a_member
error.schema #=> #<RSchema::Schemas::Enum>
error.to_s #=> "Error RSchema::Schemas::Enum/not_a_member for value: :blond"
error.to_s(:detailed) #=>
  # Error: not_a_member
  # Schema: RSchema::Schemas::Enum
  # Value: :blond
  # Vars: nil
```

Type Schemas
------------

The most basic kind of schema is a `Type` schema.
Type schemas validate the class of a value using `is_a?`.

```ruby
schema = RSchema.define { type(String) }
schema.call('hi').valid? #=> true
schema.call(1234).valid? #=> false
```

Type schemas are so common that the RSchema DSL provides a shorthand way to
create them, using an underscore prefix:

```ruby
schema1 = RSchema.define { _Integer }
# is exactly the same as
schema2 = RSchema.define { type(Integer) }
```

Because type schemas use `is_a?`, they handle subclasses, and can also be used
to check for `include`d modules like `Enumerable`:

```ruby
schema = RSchema.define { _Enumerable }
schema.call([1, 2, 3]).valid? #=> true
schema.call({ a: 1, b: 2 }).valid? #=> true
```

Variable-length Array Schemas
-----------------------------

There are two types of array schemas.
The first type are `VariableLengthArray` schemas, where every element in the
array conforms to a single subschema:

```ruby
schema = RSchema.define { Array(_Symbol) }
schema.class #=> RSchema::Schemas::VariableLengthArray

schema.call([:a, :b, :c]).valid? #=> true
schema.call([:a]).valid? #=> true
schema.call([]).valid? #=> true
```

Fixed-length Array Schemas
--------------------------

There are also `FixedLengthArray` schemas, where the array must have a specific
length, and each element of the array has a separate subschema:

```ruby
schema = RSchema.define{ Array(_Integer, _String) }
schema.class #=> RSchema::Schemas::FixedLengthArray

schema.call([10, 'hello']).valid? #=> true
schema.call([10, 'hello', 'world']).valid? #=> false
schema.call([10]).valid? #=> false
```

Fixed Hash Schemas
------------------

There are also two kinds of hash schemas.

`FixedHash` schemas describes hashes where they keys are known constants:

```ruby
schema = RSchema.define do
  Hash(name: _String, age: _Integer)
end

schema.call({ name: 'George', age: 2 }).valid? #=> true
```

Keys can be optional:

```ruby
schema = RSchema.define do
  Hash(
    name: _String,
    optional(:age) => _Integer,
  )
end

schema.call({ name: 'Lucy', age: 21 }).valid? #=> true
schema.call({ name: 'Tom' }).valid? #=> true
```

`FixedHash` schemas are common, so the `RSchema.define_hash` method exists
to make their creation more convenient:

```ruby
schema = RSchema.define_hash {{
  name: _String,
  optional(:age) => _Integer,
}}
```

Variable Hash Schemas
---------------------

`VariableHash` schemas are for hashes where the keys are _not_ known constants.
They contain one subschema for keys, and another subschema for values.

```ruby
schema = RSchema.define { VariableHash(_Symbol => _Integer) }
schema.call({}).valid? #=> true
schema.call({ a: 1 }).valid? #=> true
schema.call({ a: 1, b: 2 }).valid? #=> true
```

Other Schema Types
------------------

RSchema provides a few other schema types through its DSL:

```ruby
# boolean (only true or false)
boolean_schema = RSchema.define { Boolean() }
boolean_schema.call(true).valid?  #=> true
boolean_schema.call(false).valid? #=> true
boolean_schema.call(nil).valid?   #=> false

# anything (literally any value)
anything_schema = RSchema.define { anything }
anything_schema.call('Hi').valid?  #=> true
anything_schema.call(true).valid?  #=> true
anything_schema.call(1234).valid?  #=> true
anything_schema.call(nil).valid?   #=> true

# either (sum types)
either_schema = RSchema.define { either(_String, _Integer, _Float) }
either_schema.call('hi').valid? #=> true
either_schema.call(5555).valid? #=> true
either_schema.call(77.1).valid? #=> true

# maybe (allows nil)
maybe_schema = RSchema.define { maybe(_Integer) }
maybe_schema.call(5).valid?   #=> true
maybe_schema.call(nil).valid? #=> true

# enum (a set of valid values)
enum_schema = RSchema.define { enum([:a, :b, :c]) }
enum_schema.call(:a).valid? #=> true
enum_schema.call(:z).valid? #=> false

# predicate (block returns true for valid values)
predicate_schema = RSchema.define do
  predicate { |x| x.even? }
end
predicate_schema.call(4).valid? #=> true
predicate_schema.call(5).valid? #=> false

# pipeline (apply multiple schemas to a single value, in order)
pipeline_schema = RSchema.define do
  pipeline(
    either(_Integer, _Float),
    predicate { |x| x.positive? },
  )
end
pipeline_schema.call(123).valid? #=> true
pipeline_schema.call(5.1).valid? #=> true
pipeline_schema.call(-24).valid? #=> false
```


Coercion
--------

Coercers convert invalid data into valid data where possible, according to a
schema.

Take HTTP params as an example. Web forms often contain database IDs, which
are integers, but are submitted as strings by the browser. Param hash keys
are often expected to be `Symbol`s, but are also strings. The `HTTPCoercer`
can automatically convert these strings into the appropriate type, based on a
schema.

```ruby
# Input keys and values are all strings.
input_params = {
  'whatever_id' => '5',
  'amount' => '123.45',
}

# The schema expects symbol keys, an integer value, and a float value.
param_schema = RSchema.define_hash {{
  whatever_id: _Integer,
  amount: _Float,
}}

# The schema is wrapped in a HTTPCoercer.
coercer = RSchema::HTTPCoercer.wrap(param_schema)

# Use the coercer like a normal schema object.
result = coercer.call(input_params)

# The result object contains the coerced value
result.valid? #=> true
result.value #=> { :whatever_id => 5, :amount => 123.45 }
```

Extending The DSL
-----------------

To add methods to the default DSL, first create a module:

```ruby
module MyCustomMethods
  def palendrome
    pipeline(
      _String,
      predicate { |s| s == s.reverse },
    )
  end
end
```

Then include your module into `RSchema::DefaultDSL`:

```ruby
RSchema::DefaultDSL.include(MyCustomMethods)
```

And your methods will be available via `RSchema.define`:

```ruby
schema = RSchema.define { palendrome }

schema.call('racecar').valid? #=> true
schema.call('ferrari').valid? #=> false
```

This is the preferred way for other gems to extend RSchema with new kinds
of schema classes.


Creating Your Own DSL
---------------------

The default DSL is designed to be extended (i.e. modified) by external gems/code.
If you want a DSL that isn't affected by external factors, you can create one
yourself.

Create a new class, and include `RSchema::DSL` to get all the standard DSL
methods that come built-in to RSchema. You can define your own custom methods
on this class.

```ruby
class MyCustomDSL
  include RSchema::DSL

  def palendrome
    pipeline(
      _String,
      predicate { |s| s == s.reverse },
    )
  end
end
```

Then simply use `instance_eval` to make use of your custom DSL.

```ruby
schema = MyCustomDSL.new.instance_eval { palendrome }
schema.call('racecar').valid? #=> true
```

See the implementation of `RSchema.define` for reference.


Custom Schema Types
-------------------

Schemas are objects that conform to a certain interface (i.e. a duck type).
To create your own schema types, you just need to implement this interface.

Below is a custom schema for pairs – arrays with two elements.
This is already possible using existing schemas (e.g. `Array(_String, _String)`),
and is only shown here for the purpose of demonstration.

```ruby
class PairSchema
  def initialize(subschema)
    @subschema = subschema
  end

  def call(pair, options=RSchema::Options.default)
    return not_an_array_failure(pair) unless pair.is_a?(Array)
    return not_a_pair_failure(pair) unless pair.size == 2

    subresults = pair.map { |x| @subschema.call(x, options) }

    if subresults.all?(&:valid?)
      RSchema::Result.success(subresults.map(&:value).to_a)
    else
      RSchema::Result.failure(subschema_error(subresults))
    end
  end

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
          vars: {
            expected_size: 2,
            actual_size: pair.size,
          }
        )
      )
    end

    def subschema_error(subresults)
      subresults
        .each_with_index
        .select { |(result, idx)| result.invalid? }
        .map(&:reverse)
        .to_h
    end
end
```

Add your new schema class to the default DSL:

```ruby
module PairSchemaDSL
  def pair(subschema)
    PairSchema.new(subschema)
  end
end

RSchema::DefaultDSL.include(PairSchemaDSL)
```

Then your schema is accessible from `RSchema.define`:

```ruby
gps_coordinate_schema = RSchema.define { pair(_Float) }
gps_coordinate_schema.call([1.2, 3.4]).valid? #=> true
```

Coercion should work, as long as `#with_wrapped_subschemas` was implemented
correctly.

```ruby
coercer = RSchema::HTTPCoercer.wrap(gps_coordinate_schema)
result = coercer.call(['1', '2'])
result.valid? #=> true
result.value #=> [1.0, 2.0]
```

TODO: need to explain how to implement `#call` and `#with_wrapped_subschemas`


[Prismatic/schema]: https://github.com/Prismatic/schema

