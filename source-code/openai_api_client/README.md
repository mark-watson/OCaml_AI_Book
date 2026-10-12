# OpenAI API Client - OCaml

OCaml port of the Haskell OpenAI example. It calls the chat-completion endpoint
to generate text and to pull place and person names out of sample sentences.

## Setup

```bash
export OPENAI_API_KEY=sk-...
```

## Project layout

```
openai_api_client/
├── lib/openai.ml  <- request builder and response decoder (Yojson)
├── bin/main.ml    <- the HTTPS POST and the demo
└── test/          <- Alcotest over the JSON codec
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell code used the `openai-hs` library. Here we call the REST endpoint
  directly with Cohttp and hand-write the small JSON codec with Yojson, the same
  approach as the Ollama example.
- `lookupEnv` becomes `Sys.getenv_opt`; a missing key prints a message and exits.
- `splitOn "," . strip` becomes `split_entities`.
- The unit tests exercise the codec offline, so `make test` needs no API key.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
