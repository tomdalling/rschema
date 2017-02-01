Gem Release
-----------

1. Start with a clean working repository (commit all changes)
2. Use `sh/bump_version`, which will modify the version, commit, tag, and push to github.
3. Travis-CI will automatically build and publish the gem.


TODO
----

 - Revise/fix how Hash schemas report errors for keys.

 - Pluggable coercion.

   Could provide helper/convenience classes for creating custom coercers,
   although it won't provide any capabilities that the API doesn't already
   offer.

 - Error translations

   Errors contain a lot of information that can be translated to fit various
   context. There are already multiple developer-friendly translations, but
   these errors should probably be translatable via Rails i18n functionality.