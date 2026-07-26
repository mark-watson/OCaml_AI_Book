# Debug Tracing - OCaml

OCaml port of the Haskell `Debug.Trace` example. It shows how to print debug
output from otherwise pure code, using a prime sieve as the traced computation.

## Run

```bash
dune build
dune exec ./trace_timer.exe
```

Trace lines go to stderr; the final list of primes goes to stdout.

## Notes on the Haskell to OCaml port

- Haskell's `Debug.Trace.trace` becomes a one-line `trace` helper that writes to
  stderr with `Printf.eprintf` and returns its value.
- Haskell traces fire in lazy demand order. OCaml is strict, so to keep the same
  "trace when the value is used" behaviour the primes are a lazy `Seq.t` and each
  element is traced as it is forced by `Seq.take`.
- The infinite list `[2..]` becomes `Seq.ints 2`.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
