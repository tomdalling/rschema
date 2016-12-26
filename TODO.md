Feature Roadmap
---------------

 - Returning multiple validation errors.

   Almost done. TODO: Hash schemas have problems reporting errors for keys.

 - Monadic coercion.

   Done. Schema return values are wrapped in an `RSchema::Result` object.

 - Schema compilation.

   Basically done. Schemas are all custom objects. The last thing left to do is
   allow FixedHash schemas to have non-destructive updates (create new schemas
   from existing schemas).

 - Pluggable coercion.

   Done. Different coercers can be applied to a single schema.
   Could provide helper/convenience classes for writing custom coercers,
   although it won't provide any capabilities that the API doesn't already
   offer.

 - Symbolic errors.

   Errors contain a lot of information that can be translated to fit various
   context. There are already multiple developer-friendly translations, but
   these errors should probably be translatable via Rails i18n functionality.
