# SPARQL Client - OCaml

OCaml port of the Haskell SPARQL examples. It sends a SPARQL query to DBpedia
over HTTP and decodes the JSON result set. The demo asks for IBM's English
abstract.

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell directory had several clients (hsparql, hxt XML, aeson JSON). This
  port keeps the useful HTTP-plus-JSON case in one small `sparql.ml`.
- Manual `urlEncode` becomes `Uri.add_query_params'`, which encodes the query.
- Decoding the SPARQL 1.1 JSON results (`results.bindings[].<var>.value`) is a
  short `Yojson.Safe.Util` walk.
- The test decodes a sample result set offline, so `make test` needs no network.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
