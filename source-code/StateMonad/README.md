# State Monad - OCaml

Haskell's `State` monad comes from the `mtl` library. OCaml has no such built-in, so this example defines a small `State` module: a stateful computation is a function from a start state to a `(result, new state)` pair.

## Run

```bash
dune build
dune exec ./state1.exe
```

Expected output:

```
(1,2)
(1,2)
(2,4)
1
2
```

## Notes on the Haskell to OCaml port

- `get`, `put`, `return`, `>>=`, `>>`, `runState`, `evalState`, `execState`, and `mapState` all map to functions in the `State` module.
- The `let*` binding operator gives the same readable sequencing as Haskell `do` notation.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
