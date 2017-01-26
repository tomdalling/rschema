TODO
====

 - Revise/fix how Hash schemas report errors for keys.

 - Pluggable coercion.

   Could provide helper/convenience classes for creating custom coercers,
   although it won't provide any capabilities that the API doesn't already
   offer.

 - Error translations

   Errors contain a lot of information that can be translated to fit various
   context. There are already multiple developer-friendly translations, but
   these errors should probably be translatable via Rails i18n functionality.
