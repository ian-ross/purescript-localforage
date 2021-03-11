{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "localforage"
, dependencies =
  [ "aff"
  , "console"
  , "effect"
  , "foreign"
  , "prelude"
  , "psci-support"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
