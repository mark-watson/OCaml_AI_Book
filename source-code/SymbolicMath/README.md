# Symbolic Math - OCaml

A small library for symbolic differentiation and integration of single-variable polynomials. OCaml port of the Haskell version.

## Project layout

```
SymbolicMath/
├── dune-project
├── src/
│   ├── rational.ml        <- exact rational numbers (OCaml has no built-in Rational)
│   ├── types.ml           <- domains, variables, constants, terms, polynomials, integrals
│   ├── differentiation.ml <- power rule and derivatives
│   └── integration.ml     <- reverse power rule and definite integrals
├── bin/main.ml            <- smoke test runner
└── test/                  <- Alcotest suite
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- Haskell `Rational` becomes a hand-written `Rational` module using two `int` fields kept in lowest terms.
- Haskell's `Either Rational Constant` bound becomes a `bound` variant (`BNum` / `BConst`).
- Haskell's single overloaded `polynomialEvaluate` splits into `polynomial_evaluate` (float) and `polynomial_evaluate_q` (exact rational), since OCaml has no `Fractional` type class.
- The HSpec tests become an Alcotest suite with the same cases.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
