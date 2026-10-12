# Pure OCaml Tutorial Examples

OCaml port of the "pure" tutorial chapter. Each file shows one idea: pattern matching, branching, `let` bindings, `map`, function composition, and custom variant types.

## Run

```bash
dune build
dune exec ./simple.exe
dune exec ./conditionals.exe
dune exec ./guards.exe
dune exec ./cases.exe
dune exec ./let_and_where.exe
dune exec ./chained_calls.exe
dune exec ./map_examples.exe
dune exec ./my_colors.exe
dune exec ./if_then_else.exe
```

## Source Files

| File | Description |
|------|-------------|
| `simple.ml` | Basic function definition |
| `conditionals.ml` | Pattern matching and list recursion |
| `if_then_else.ml` | `if`/`then`/`else` as an expression |
| `guards.ml` | Branching and `option` values |
| `cases.ml` | `match` expressions |
| `let_and_where.ml` | `let` bindings and list comprehension |
| `chained_calls.ml` | Function composition and application |
| `map_examples.ml` | The standard `Map` functor |
| `my_colors.ml` | A variant type with a custom compare |

## Notes on the Haskell to OCaml port

- Haskell guards become nested `if`/`match` since OCaml has no guard syntax on plain definitions.
- Haskell `where` becomes `let ... in`.
- Haskell `show`/`print` on lists becomes small helper functions, since OCaml has no automatic `Show`.
- Haskell's `$` maps to `@@`, and `.` composition to a small `compose` helper or `|>`.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
