# RSchema

Schema-based validation and coercion for Ruby data structures. Heavily inspired
by (read: stolen from) [Prismatic/schema][] for Clojure.

Meet RSchema
------------

A "schema" is a data structure that describes the _shape_ of data.
Schemas are generally just plain old hashes, arrays, and classes.

```ruby
post_schema = {
  title: String,
  tags: Array[Symbol],
  body: String
}
```

Schemas can be used to validate data. That is, they can check whether
data is in the correct shape:

```ruby
RSchema.validate(post_schema, {
  title: "You won't beleive how this developer foo'd her bar",
  tags: [:foos, :bars, :unbeleivable],
  body: '<p>blah blah</p>'
}) #=> true
```

What is a schema?
-----------------

Schemas are Ruby data structures. The simplest type of schema is just a class:

```ruby
schema = Integer
RSchema.validate(schema, 5) #=> true
RSchema.validate(schema, 'hello') #=> false
```

Then there are composite schemas, which are schemas composed of subschemas.
Arrays are composite schemas:

```ruby
schema = Array[Integer]
RSchema.validate(schema, [10, 11, 12]) #=> true
RSchema.validate(schema, [10, 11, '12']) #=> false
```

And so are hashes:

```ruby
schema = { fname: String, age: Integer }
RSchema.validate(schema, { fname: 'Jane', age: 27 }) #=> true
RSchema.validate(schema, { fname: 'Johnny' }) #=> false
```

While schemas are just plain old Ruby data structures, RSchema also provides
an extensible DSL for constructing more complicated schemas:

```ruby
schema = RSchema.schema {{
  fname: predicate { |n| n.is_a?(String) && n.size > 0 },
  favourite_foods: set_of(Symbol),
  children_by_age: hash_of(Integer => String)
}}

RSchema.validate(schema, {
  fname: 'Johnny',
  favourite_foods: Set.new([:bacon, :cheese, :onion]),
  children_by_age: {
    7 => 'Jenny',
    5 => 'Simon'
  }
}) #=> true
```

When Validation Fails
---------------------

Using `RSchema.validate`, it is often difficult to tell exactly which values
are failing validation.

```ruby
schema = RSchema.schema do
  Array[{
    name: String,
    hair: enum([:red, :brown, :blonde, :black])
  }]
end

value = [
  { name: 'Dane', hair: :black },
  { name: 'Tom', hair: :brown },
  { name: 'Effie', hair: :blond },
  { name: 'Chris', hair: :red },
]

RSchema.validate(schema, value) #=> false
```

To see exactly where validation fails, we can look at an
`RSchema::ErrorDetails` object.

The `validate!` method throws an exception when validation fails, and the
exception contains the `RSchema::ErrorDetails` object.

```ruby
RSchema.validate!(schema, value) # throws exception:
#=> RSchema::ValidationError: The value at [2, :hair] is not a valid enum member: :blond
```

The error above says that the value `:blond`, which exists at location
`value[2][:hair]`, is not a valid enum member. Looking back at the schema, we
see that there is a typo, and it should be `:blonde` instead of `:blond`.

To get an `RSchema::ErrorDetails` object _without_ using exceptions, we can use
the `RSchema.validation_error` method.

```ruby
error_details = RSchema.validation_error(schema, value)

error_details.failing_value #=> :blond
error_details.reason #=> "is not a valid enum member"
error_details.key_path #=> [2, :hair]
error_details.to_s #=> "The value at [2, :hair] is not a valid enum member: :blond"
```

Array Schemas
-------------

There are two types of array schemas. When the array schema has a single
element, it is a variable-length array schema:

```ruby
schema = Array[Symbol]
RSchema.validate(schema, [:a, :b, :c]) #=> true
RSchema.validate(schema, [:a]) #=> true
RSchema.validate(schema, []) #=> true
```

Otherwise, it is a fixed-length array schema

```ruby
schema = Array[Integer, String]
RSchema.validate(schema, [10, 'hello']) #=> true
RSchema.validate(schema, [10, 'hello', 'world']) #=> false
RSchema.validate(schema, [10]) #=> false
```

Hash Schemas
------------

Hash schemas map constant keys to subschema values:

```ruby
schema = { fname: String }
RSchema.validate(schema, { fname: 'William' }) #=> true
```

Keys can be optional:

```ruby
schema = RSchema.schema {{
  :fname => String,
  optional(:age) => Integer
}}
RSchema.validate(schema, { fname: 'Lucy', age: 21 }) #=> true
RSchema.validate(schema, { fname: 'Tom' }) #=> true
```

There is also another type of hash schema that represents hashes with variable
keys:

```ruby
schema = RSchema.schema { hash_of(String => Integer) }
RSchema.validate(schema, { 'hello' => 1, 'world' => 2 }) #=> true
RSchema.validate(schema, { 'hello' => 1 }) #=> true
RSchema.validate(schema, {}) #=> true
```

Other Schema Types
------------------

RSchema provides a few other schema types through its DSL:

```ruby
# boolean
boolean_schema = RSchema.schema{ boolean }
RSchema.validate(boolean_schema, false) #=> true
RSchema.validate(boolean_schema, nil)   #=> false

# any
any_schema = RSchema.schema{ any }
RSchema.validate(any_schema, "Hi")  #=> true
RSchema.validate(any_schema, true)  #=> true
RSchema.validate(any_schema, false) #=> true
RSchema.validate(any_schema, nil)   #=> true

# maybe
maybe_schema = RSchema.schema{ maybe(Integer) }
RSchema.validate(maybe_schema, 5)   #=> true
RSchema.validate(maybe_schema, nil) #=> true

# enum
enum_schema = RSchema.schema{ enum([:a, :b, :c]) }
RSchema.validate(enum_schema, :a) #=> true
RSchema.validate(enum_schema, :z) #=> false

# predicate
predicate_schema = RSchema.schema do
  predicate('even') { |x| x.even? }
end
RSchema.validate(predicate_schema, 4) #=> true
RSchema.validate(predicate_schema, 5) #=> false
```

Coercion
--------

RSchema is capable of coercing invalid values into valid ones, in some
situations. Here are some examples:

```ruby
RSchema.coerce!(Symbol, "hello") #=> :hello
RSchema.coerce!(String, :hello)  #=> "hello"
RSchema.coerce!(Integer, "5")    #=> 5
RSchema.coerce!(Integer, "cat")  # !!! raises RSchema::ValidationError !!!
RSchema.coerce!(Set, [1, 2, 3])  #=> <Set: {1, 2, 3}>

schema = RSchema.schema {{
  fname: String,
  favourite_foods: set_of(Symbol)
}}

value = {
  fname: 'Peggy',
  favourite_foods: ['berries', 'cake']
}

RSchema.coerce!(schema, value)
  #=> { fname: "Peggy", favourite_foods: <Set: #{:berries, :cake}> }
```

Extending the DSL
-----------------

You can create new, custom DSLs that extend the default DSL like so:

```ruby
module MyCustomDSL
  extend RSchema::DSL::Base
  def self.positive_and_even(type)
    predicate { |x| x > 0 && x.even? }
  end
end
```

Pass the custom DSL to `RSchema.schema` to use it:

```ruby
schema = RSchema.schema(MyCustomDSL) { positive_and_even }
RSchema.validate(schema, 6)  #=> true
RSchema.validate(schema, -6) #=> false
```

Custom Schema Types
-------------------

Any Ruby object can be a schema, as long as it implements the `schema_walk`
method.  Here is a schema called `Coordinate`, which is an x/y pair of `Float`s
in an array:

```ruby
# make the schema type class
class CoordinateSchema
  def schema_walk(value, mapper)
    # validate `value`
    return RSchema::ErrorDetails.new(value, 'is not an Array') unless value.is_a?(Array)
    return RSchema::ErrorDetails.new(value, 'does not have two elements') unless value.size == 2

    # walk the subschemas/subvalues
    x, x_error = RSchema.walk(Float, value[0], mapper)
    y, y_error = RSchema.walk(Float, value[1], mapper)

    # look for subschema errors, and propagate them if found
    return x_error.extend_key_path(:x) if x_error
    return y_error.extend_key_path(:y) if y_error

    # return the valid value
    [x, y]
  end
end

# add some DSL
module RSchema::DSL
  def self.coordinate
    CoordinateSchema.new
  end
end

# use the custom schema type (coercion works too)
schema = RSchema.schema { coordinate }
RSchema.validate(schema, [1.0, 2.0]) #=> true
RSchema.validate(schema, [1, 2]) #=> false
RSchema.coerce!(schema, ["1", "2"]) #=> [1.0, 2.0]
```

The `schema_walk` method receives two arguments:

 - `value`: the value that is being validated against this schema
 - `mapper`: not usually used by the schema, but must be passed to
   `RSchema.walk`.

The `schema_walk` method has three responsibilities:

 1. It must validate the given value. If the value is invalid, the method must
    return an `RSchema::ErrorDetails` object. If the value is valid, it must
    return the valid value after walking all subvalues.

 2. For composite schemas, it must walk subvalues by calling `RSchema.walk`.
    The example above walks two subvalues (`value[0]` and `value[1]`) with the
    `Float` schema.

 3. It must propagate any `RSchema::ErrorDetails` objects returned from walking
    the subvalues. Walking subvalues with `RSchema.walk` may return an error,
    in which case the `rschema_walk` method must also return an error. Use the
    method `RSchema::ErrorDetails#extend_key_path` in this situation, to
    include additional information in the error before returning it.

[Prismatic/schema]: https://github.com/Prismatic/schema

