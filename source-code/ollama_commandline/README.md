# Ollama command-line client

A command-line client for [Ollama](https://ollama.com/)'s local API. Sends a prompt to a running Ollama service and prints the model's response.

## Quick start

Make sure Ollama is running locally (port 11434) with at least one model pulled:

```bash
ollama serve        # start the service if not already running
ollama pull qwen3:1.7b
```

Build and run:

```bash
dune build
dune exec bin/main.exe -- "What is the capital of France?"
```

With a specific model:

```bash
dune exec bin/main.exe -- "Explain monads" "llama3.2"
```

Run the tests:

```bash
dune test
```

## What it demonstrates

- **Manual JSON codec** with Yojson -- constructing POST bodies and parsing API responses field by field, mirroring how you would handle any REST API
- **HTTP POST with Cohttp/Lwt** -- setting headers, sending a JSON body, and reading the response
- **Error handling** -- connection failures, non-200 status codes, and JSON parse errors each produce a clear message
- **Module organisation** -- types and codec live in a shared library module (`Ollama`) separate from the executable and the tests
- **Alcotest** unit tests for JSON round-tripping, matching the structure of the Haskell original

## Project structure

```
ollama_commandline/
  lib/
    ollama.mli    -- public types and function signatures
    ollama.ml     -- JSON encoders and decoders
    dune          -- library build config (depends on yojson)
  bin/
    main.ml       -- CLI entry point and HTTP call
    dune          -- executable build config (depends on cohttp-lwt-unix)
  test/
    test_ollama.ml -- 5 unit tests for JSON encode/decode
    dune           -- test build config (depends on alcotest)
  dune-project
  README.md
```

## API details

The client calls Ollama's `/api/generate` endpoint with `stream: false`. The request body has three fields:

```json
{"model": "qwen3:1.7b", "prompt": "Your prompt here", "stream": false}
```

The response is parsed into the `ollama_response` record, and errors from the API are parsed into `ollama_error`.
