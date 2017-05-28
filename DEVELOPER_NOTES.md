Gem Release
-----------

 1. Start with a clean working repository (commit all changes)
 2. Bump the version with:

    bundle exec gem bump --version [major|minor|patch|pre|release]

 3. Tag and push the commit with:

    bundle exec gem tag

 4. Travis-CI will automatically build and publish the gem.


TODO
----

 - Unit tests for CoercionWrapper

 - Error translations

   Errors contain a lot of information that can be translated to fit various
   contexts. There are already developer-friendly ways to stringify errors, but
   these errors should probably be translatable via Rails i18n functionality.
