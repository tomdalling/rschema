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
  tags: [Symbol],
  body: String
}
```

Schemas can be used to validate data. That is, they can check whether
data is in the correct shape:

```ruby
RSchema.validate!(post_schema, {
  title: "You won't beleive how this developer foo'd her bar",
  tags: [:foos, :bars, :unbeleivable],
  body: '<p>blah blah</p>'
}) # ok
```

What is a schema?
-----------------

Schemas are Ruby data structures. The simplest type of schema is just a class:

```ruby
schema = Integer
RSchema.validate!(schema, 5)       # ok
RSchema.validate!(schema, 'hello') # !!! raises RSchema::ValidationError !!!
```

Then there are composite schemas, which are schemas composed of subschemas.
Arrays are composite schemas:

```ruby
schema = [Integer]
RSchema.validate!(schema, [10, 11, 12])   # ok
RSchema.validate!(schema, [10, 11, '12']) # !!! raises RSchema::ValidationError !!!
```

And so are hashes:

```ruby
schema = { fname: String, age: Integer }
RSchema.validate!(schema, { fname: 'Jane', age: 27 }) # ok
RSchema.validate!(schema, { fname: 'Johnny' })        # !!! raises RSchema::ValidationError !!!
```

While schemas are just plain old Ruby data structures, RSchema also provides
an extensible DSL for constructing more complicated schemas:

```ruby
schema = RSchema.schema {{
  fname: predicate { |n| n.is_a?(String) && n.size > 0 },
  favourite_foods: set_of(Symbol),
  children_by_age: hash_of(Integer => String)
}}

RSchema.validate!(schema, {
  fname: 'Johnny',
  favourite_foods: Set.new([:bacon, :cheese, :onion]),
  children_by_age: {
    7 => 'Jenny',
    5 => 'Simon'
  }
}) # ok
```

Array Schemas
-------------

There are two types of array schemas. When the array schema has a single
element, it is a variable-length array schema:

```ruby
schema = [Symbol]
RSchema.validate!(schema, [:a, :b, :c]) # ok
RSchema.validate!(schema, [:a])         # ok
RSchema.validate!(schema, [])           # ok
```

Otherwise, it is a fixed-length array schema

```ruby
schema = [Integer, String]
RSchema.validate!(schema, [10, 'hello'])          # ok
RSchema.validate!(schema, [10, 'hello', 'world']) # !!! raises RSchema::ValidationError !!!
RSchema.validate!(schema, [10])                   # !!! raises RSchema::ValidationError !!!
```

Hash Schemas
------------

Hash schemas map constant keys to subschema values:

```ruby
schema = { fname: String }
RSchema.validate!(schema, { fname: 'William' }) # ok
```

Keys can be optional:

```ruby
schema = RSchema.schema {{
  :fname => String,
  _?(:age) => Integer
}}
RSchema.validate!(schema, { fname: 'Lucy', age: 21 }) # ok
RSchema.validate!(schema, { fname: 'Tom' })           # ok
```

There is also another type of hash schema that represents hashes with variable
keys:

```ruby
schema = RSchema.schema { hash_of(String => Integer) }
RSchema.validate!(schema, { 'hello' => 1, 'world' => 2 }) # ok
RSchema.validate!(schema, { 'hello' => 1 })               # ok
RSchema.validate!(schema, {})                             # ok
```

Other Schema Types
------------------

RSchema provides a few other schema types through its DSL:

```ruby
# predicate
predicate_schema = RSchema.schema do
  predicate('even') { |x| x.even? }
end
RSchema.validate!(predicate_schema, 4) # ok
RSchema.validate!(predicate_schema, 5) # !!! raises RSchema::ValidationError !!!

# maybe
maybe_schema = RSchema.schema do
  maybe(Integer)
end
RSchema.validate!(maybe_schema, 5)   # ok
RSchema.validate!(maybe_schema, nil) # ok

# enum
enum_schema = RSchema.schema do
  enum([:a, :b, :c])
end
RSchema.validate!(enum_schema, :a) # ok
RSchema.validate!(enum_schema, :z) # !!! raises RSchema::ValidationError !!!
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

The RSchema DSL can be extended by adding methods to the `RSchema::DSL` module:

```ruby
module RSchema::DSL
  def self.positive_and_even(type)
    predicate { |x| x > 0 && x.even? }
  end
end

schema = RSchema.schema { positive_and_even }
RSchema.validate!(schema, 6)  # ok
RSchema.validate!(schema, -6) # !!! raises RSchema::ValidationError !!!
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
    return RSchema::ErrorDetails.new('is not an Array') unless value.is_a?(Array)
    return RSchema::ErrorDetails.new('does not have two elements') unless value.size == 2

    # walk the subschemas/subvalues
    x, x_error = RSchema.walk(Float, value[0], mapper)
    y, y_error = RSchema.walk(Float, value[1], mapper)

    # look for subschema errors, and propagate them if found
    return RSchema::ErrorDetails.new({ x: x_error.details }) if x_error
    return RSchema::ErrorDetails.new({ y: y_error.details }) if y_error

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
RSchema.validate!(schema, [1.0, 2.0]) # ok
RSchema.validate!(schema, [1, 2])     # !!! raises RSchema::ValidationError !!!
RSchema.coerce!(schema, ["1", "2"])   #=> [1.0, 2.0]
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
    in which case the `rschema_walk` method must also return an error.

[Prismatic/schema]: https://github.com/Prismatic/schema

