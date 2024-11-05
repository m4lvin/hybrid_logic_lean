import Lake
open Lake DSL

package hybrid {
  -- add package configuration options here
}

@[default_target]
lean_lib Hybrid {
  -- add library configuration options here
}

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"@"v4.13.0"
