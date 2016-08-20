Feature Roadmap
---------------

 - Returning multiple validation errors.

   RSchema currently bails out when the first validation error is encountered.
   It would be better if validation continued, collecting all errors and then
   returning them. This is important when displaying errors to a user/developer,
   so that they can fix all the errors at once, instead of fixing one at a time.

 - Monadic coercion.

   At the moment, `coerce` returns a `[result, error]` tuple, but it would
   probably be better as a custom object, maybe a `RSchema::Result` class.
   Example:

         result = RSchema.coerce(schema, value)
         if result.valid?
           puts result.value
         else
           puts result.errors
         end

 - Schema compilation.

   At the moment schemas contain hashes and arrays. It would probably be better
   if these were "compiled" into custom schema objects, so we can stop monkey
   patching the `schema_walk` method onto Class/Array/Hash. The array and hash
   schema objects would still need an interface for modification, for example:

         new_schema = old_schema.merge(new_attributes)

   This is so that schemas can be made from existing schemas. The common use
   case for this is two model schemas, one with an `id` attribute, and one
   without `id` that is only used when inserting a model object into the DB.

 - Pluggable coercion.

   Coercion logic is currently hard coded. You can swap out the entire coercer,
   but you can't plug new coercions into the existing coercer.

   This is tricky because it required double dispatch on the schema and value,
   and you need to take precedence into account when there are multiple valid
   coercions to choose from.

   Coercion logic probably shouldn't belong in the schema objects, because
   the same schema can require different coercion logic depending on the
   context. For example, in a HTTP param context, it might be desirable for
   the string `"1"` to be coerced to `true` for a `BooleanSchema`. In a
   different context, however, it may be preferable for all strings to result
   in a validation error instead.

 - Symbolic errors.

   Error messages are currently hard-coded in English, which makes them
   difficult to translate. It would be better if error messages were symbols
   that could be easily fed into i18n.


Gem Release Procedure
---------------------

1. Add a new section to `CHANGELOG.md` and commit those changes
2. Bump version with `sh/bump_version <VERSION>`
3. Check that the new version is correct
4. Release with `sh/release`

