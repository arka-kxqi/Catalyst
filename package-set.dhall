let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.12.1-20240808/package-set.dhall sha256:975d4b33f3ce1fa051c73e45fab69dd187dba6b037b6d2e5568ccac26c477d4f
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [
      { name = "map"
      , version = "v9.0.1"
      , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
      , dependencies = [] : List Text
      },
      { name = "vector"
      , version = "main"
      , repo = "https://github.com/research-ag/vector"
      , dependencies = [] : List Text
      },
      { name = "encoding"
      , repo = "https://github.com/aviate-labs/encoding.mo"
      , version = "v0.3.1"
      , dependencies = [ "array", "base" ]
      },
      { name = "array"
      , repo = "https://github.com/aviate-labs/array.mo"
      , version = "v0.1.1"
      , dependencies = [ "base" ]
      }
    ] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides