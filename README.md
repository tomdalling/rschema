# RSchema

Schema-based validation and coercion for Ruby data structures. It has heavily
inspired by (read: stolen from) [Prismatic/schema][] for Clojure.

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
schema = [Integer]
RSchema.validate(schema, [1, 2, 3]) #=> true
RSchema.validate(schema, [1, 2, '3']) #=> false
```

And so are hashes:

```ruby
schema = {name: String, age: Integer}
RSchema.validate(schema, {name: 'Jane', age: 27}) #=> true
RSchema.validate(schema, {name: 'Johnny'}) #=> false
```

While schemas are just plain old Ruby data structures, RSchema also provides
an extensible DSL for constructing more complicated schemas:

```ruby
schema = RSchema.schema {{
  name: predicate { |n| n.is_a?(String) && n.size > 0 },
  favourite_foods: set_of(Symbol),
  children_by_age: hash_of(Integer => String)
}}

RSchema.validate(schema, {
  name: 'Johnny',
  favourite_foods: Set.new([:bacon, :cheese, :onion]),
  children_by_age: {
    7 => 'Jenny',
    5 => 'Simon'
  }
}) #=> true
```

Array Schemas
-------------

There are two types of array schemas. When the array schema has a single
element, it is a variable-length array schema:

```ruby
schema = [Symbol]
RSchema.validate(schema, [:a, :b, :c]) #=> true
RSchema.validate(schema, [:a]) #=> true
RSchema.validate(schema, []) #=> true
```

Otherwise, it is a fixed-length array schema

```ruby
schema = [Integer, String]

RSchema.validate(schema, [10, 'hello']) #=> true

RSchema.validate(schema, [10, 'hello', 'world']) #=> false
RSchema.validate(schema, [10]) #=> false
```

Hash Schemas
------------

Hash schemas map constant keys to subschema values:

```ruby
schema = { name: String }
RSchema.validate(schema, { name: 'William' }) #=> true
```

Keys can be optional:

```ruby
schema = RSchema.schema {{
  name: String,
  _?(:age) => Integer
}}
RSchema.validate(schema, { name: 'Lucy', age: 21 }) #=> true
RSchema.validate(schema, { name: 'Tom' }) #=> true
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
# predicate
predicate_schema = RSchema.schema do
  predicate { |x| x.even? }
end
RSchema.validate(predicate_schema, 4) #=> true
RSchema.validate(predicate_schema, 5) #=> false

# maybe
maybe_schema = RSchema.schema do
  maybe(Integer)
end
RSchema.validate(maybe_schema, 5) #=> true
RSchema.validate(maybe_schema, nil) #=> true

#enum
enum_schema = RSchema.schema do
  enum([:a, :b, :c])
end
RSchema.validate(enum_schema, :a) #=> true
RSchema.validate(enum_schema, :d) #=> false
```

Coercion
--------

RSchema is capable of coercing invalid values into valid ones, in some
situations. Here are some examples:

```ruby
RSchema.coerce(Symbol, "hello") #=> :hello
RSchema.coerce(String, :hello) #=> "hello"
RSchema.coerce(Integer, "5") #=> 5
RSchema.coerce(Integer, "5asdasd") #=> nil
RSchema.coerce(Set, [1, 2, 3]) #=> <Set: {1, 2, 3}>

schema = RSchema.schema {{
  name: String,
  favourite_foods: set_of(Symbol)
}}

value = {
  name: 'Peggy',
  favourite_foods: ['berries', 'cake']
}

RSchema.coerce(schema, value) #=>
#   {
#     name: "Peggy",
#     favourite_foods: <Set: #{:berries, :cake}>
#   }
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
RSchema.validate(schema, 6) #=> true
RSchema.validate(schema, -6) #=> false
```

Custom Schema Types
-------------------

Any Ruby object can be a schema, as long as there is a "walker" registered for
it's type. Here is a schema called `Coordinate`, which is an x/y pair of
`Float`s in an array:

```ruby
# make the schema type class
class CoordinateSchema
end

# make a walker
module CoordinateWalker
  def self.walk(coordinate_schema, value, mapper)
    # validate `value`
    return RSchema::ErrorDetails.new('is not an Array') unless value.is_a?(Array)
    return RSchema::ErrorDetails.new('does not have two elements') unless value.size == 2

    # walk the subschemas/subvalues
    x = RSchema.walk(Float, value[0], mapper)
    y = RSchema.walk(Float, value[1], mapper)

    # look for subschema errors, and propagate them if found
    return RSchema::ErrorDetails.new({x: x}) if x.is_a?(RSchema::ErrorDetails)
    return RSchema::ErrorDetails.new({y: y}) if y.is_a?(RSchema::ErrorDetails)

    # return the valid value
    [x, y]
  end
end

# register the walker for the schema type class
RSchema.register_walker(CoordinateSchema, CoordinateWalker)

# add some DSL
module RSchema::DSL
  def self.coordinate
    CoordinateSchema.new
  end
end

# use the custom schema type (coercion works too)
schema = RSchema.schema { coordinate }
RSchema.validate(schema, [1.0, 2.0]) #=> true
RSchema.validate(schema, [1, 2]) #=> false (not Floats)
RSchema.coerce(schema, ["1", "2"]) #=> [1.0, 2.0]
```

A walker is an object that responds to the `walk` method. The `walk` method
receives three arguments:

 - `schema`: the schema object
 - `value`: the value that is being validated against `schema`
 - `mapper`: not usually used by the walker, but must be passed to
   `RSchema.walk`

Walkers have three responsibilities:

 1. They must validate the given value against the given schema. If the value
    is invalid, the method must return a `RSchema::ErrorDetails` object. If the
    value _is_ valid, then the method must return the value after its subvalues
    have been walked.

 2. They must walk subvalues by calling `RSchema.walk`. In the example above,
    the walker walks the two elements inside the value array.

 3. They must propagate any `RSchema::ErrorDetails` objects returned from
    walking the subvalues. Walking subvalues with `RSchema.walk` may return
    an error, in which case the walker must also return an error.

[Prismatic/schema]: https://github.com/Prismatic/schema
