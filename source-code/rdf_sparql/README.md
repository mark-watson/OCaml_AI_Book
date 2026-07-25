# Simple RDF and SPARQL - OCaml

An in-memory RDF store and a small SPARQL-style query engine. No external RDF library: it uses the standard `Map` and list operations. OCaml port of the Haskell version.

## Project layout

```
rdf_sparql/
├── src/simple_rdf.ml   <- node type, triple store, pattern matcher, query engine
├── bin/simple.ml       <- queries built directly as data
├── bin/with_sparql.ml  <- queries parsed from SPARQL text
└── test/               <- Alcotest suite
```

## Build and run

```bash
dune build
dune exec ./bin/simple.exe
dune exec ./bin/with_sparql.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The list monad join in `evaluatePatterns` becomes `List.concat_map` over the recursive results.
- Haskell `nub` becomes a small order-preserving helper.
- The `ReadP` parser combinator query parser becomes a short recursive descent parser.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
