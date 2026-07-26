# Gemini Command-Line Client - OCaml

OCaml port of the Haskell Gemini example. With no argument it extracts place,
person, and company names from sample text; with an argument it runs a single
completion.

## Setup

```bash
export GOOGLE_API_KEY=your-key-here
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe                 # demo entity extraction
dune exec ./bin/main.exe -- "Explain OCaml functors"
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell `Gemini` module derived JSON via Generics. Here `gemini.ml` builds
  the request and reads the response by hand with Yojson.
- `extractEntities` with its partial applications (`findPlaces`, `findPeople`,
  `findCompanyNames`) becomes one `extract_entities` with labelled arguments.
- Network and decode failures return a `result`, printed as a clear message.
- The tests exercise the codec offline, so `make test` needs no API key.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
