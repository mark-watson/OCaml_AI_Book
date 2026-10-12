# Brave Search API Client - OCaml

OCaml port of the Haskell Brave Search example. It sends a query to the Brave
Search API and prints the original query plus one line per web result.

## Setup

```bash
export BRAVE_SEARCH_API_KEY=your-token
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe -- "OCaml programming"
dune runtest
```

## Notes on the Haskell to OCaml port

- The `Data.Aeson` `FromJSON` instances become small `*_of_json` decoders using
  `Yojson.Safe.Util`; optional fields use a tiny `opt` helper in place of `.:?`.
- `setRequestQueryString` becomes `Uri.add_query_params'`, which URL-encodes the
  query for us.
- `RecordWildCards` field access becomes ordinary record fields.
- The tests decode a sample response offline, so `make test` needs no API token.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
