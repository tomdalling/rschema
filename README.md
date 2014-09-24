# RSchema

Schema-based validation and coercion for Ruby data structures.

# Meet RSchema

A "schema" is a data structure that describes the _shape_ of data.
Schemas are generally just plain old hashes, arrays, and classes.

    post_schema = {
      title: String,
      tags: [Symbol],
      body: String
    }

Schemas can be used to validate data. That is, they can check whether
data is in the correct shape:

    RSchema.validate(post_schema, {
      title: "You won't beleive how this developer foo'd her bar",
      tags: [:foos, :bars, :unbeleivable],
      body: '<p>blah blah</p>'
    })
    #=> true

It can tell when keys are missing:

    RSchema.validate(post_schema, {
      title: 'Missing body',
      tags: [:missing, :body],
    })
    #=> false

It can tell when data is not the correct type:

    RSchema.validate(post_schema, {
      title: 'Tags are not Symbols',
      tags: ['a', 'b', 'c'],
      body: '<p>blah blah</p>'
    })
    #=> false

