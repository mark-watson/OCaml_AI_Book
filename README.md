# OCaml AI Book

Source code and examples for the **OCaml AI Book** by Mark Watson.

The examples are OCaml ports of the code from my Haskell book. They cover OCaml language basics, functional patterns, symbolic math, text processing and NLP, RDF and SPARQL, web and database access, LLM and search clients, and three games (blackjack, bridge, and Go).

All code lives under [`source-code/`](source-code/). Each example is its own [dune](https://dune.build/) project with a build, a runnable program, and a test suite.

## Examples

### Language and functional basics

| Directory | What it shows |
|-----------|---------------|
| [`pure`](source-code/pure/) | Pattern matching, branching, `let` bindings, `map`, composition, variant types |
| [`testing`](source-code/testing/) | Unit testing with Alcotest and a custom ordering |
| [`impure`](source-code/impure/) | I/O, reading files, and set intersection |
| [`command_line_app`](source-code/command_line_app/) | Command-line I/O, file handling, a guessing game |
| [`state_monad`](source-code/state_monad/) | A small `State` module that threads state through a computation, then the same with OCaml 5 effect handlers |
| [`debugging`](source-code/debugging/) | Trace-style debugging with a lazy prime sieve |
| [`timers`](source-code/timers/) | Timing and a `SIGALRM` timeout |

### Math, text, and NLP

| Directory | What it shows |
|-----------|---------------|
| [`symbolic_math`](source-code/symbolic_math/) | Symbolic differentiation and integration, with exact rationals |
| [`text_processing`](source-code/text_processing/) | Clean free text, drop stop words, read CSV and JSON |
| [`fast_tag`](source-code/fast_tag/) | A simplified Brill part-of-speech tagger |
| [`nlp_tool`](source-code/nlp_tool/) | Categorize, summarize, detect entities; Porter stemmer and sentence segmenter |
| [`knowledge_graph_creator`](source-code/knowledge_graph_creator/) | Generate RDF triples and Neo4j Cypher from text files |
| [`dataframe_example`](source-code/dataframe_example/) | A small dataframe over the `csv` library |

### Web, data, and services

| Directory | What it shows |
|-----------|---------------|
| [`web_scraping`](source-code/web_scraping/) | HTML scraping with lambdasoup and cohttp |
| [`database_sqlite`](source-code/database_sqlite/) | SQLite access with Caqti |
| [`rdf_sparql`](source-code/rdf_sparql/) | An in-memory RDF store and SPARQL-style query engine |
| [`sparql_client`](source-code/sparql_client/) | DBpedia SPARQL queries over HTTP |
| [`client_server`](source-code/client_server/) | A TCP client and server with Lwt sockets |
| [`webchat`](source-code/webchat/) | A Dream chat app backed by Gemini |
| [`webview`](source-code/webview/) | Dream "web view" apps (counter, hello) with a JS bridge |

### LLM and search clients

| Directory | What it shows |
|-----------|---------------|
| [`ollama_commandline`](source-code/ollama_commandline/) | A command-line client for a local [Ollama](https://ollama.com/) model |
| [`openai_api_client`](source-code/openai_api_client/) | OpenAI chat completions |
| [`gemini_commandline`](source-code/gemini_commandline/) | Gemini text generation and entity extraction |
| [`brave_search`](source-code/brave_search/) | The Brave Search API |

### Neural networks

| Directory | What it shows |
|-----------|---------------|
| [`neural_network`](source-code/neural_network/) | A multilayer perceptron trained with backpropagation, from scratch |

### Games

| Directory | What it shows |
|-----------|---------------|
| [`blackjack`](source-code/blackjack/) | Console blackjack with a card engine |
| [`bridge_game`](source-code/bridge_game/) | A contract bridge engine with AI bidding and play |
| [`bridge_webkit`](source-code/bridge_webkit/) | A Dream web UI over the bridge engine |
| [`go_playing_program`](source-code/go_playing_program/) | A Go board engine (captures, ko, scoring) with a self-play agent and parallel playouts on OCaml 5 domains |

## Setup

Install OCaml 5.3 or later (the book uses 5.5.1) and dune with [opam](https://opam.ocaml.org/), then add the libraries the examples use:

```bash
opam switch create 5.5.1
eval $(opam env)
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest csv lambdasoup caqti caqti-lwt caqti-driver-sqlite3 dream
```

Each example also has its own generated `.opam` file, so you can install only what one example needs:

```bash
cd source-code/webchat
opam install . --deps-only --with-test
```

## Build and run one example

```bash
cd source-code/pure
dune build
dune exec ./simple.exe
dune runtest
```

Each example directory has its own `README.md` with the exact commands to build, run, and test it.

## Build and test everything

The [`source-code/Makefile`](source-code/Makefile) recurses into every example:

GitHub Actions runs `make test` on every push and pull request (see [`.github/workflows/test.yml`](.github/workflows/test.yml)).

```bash
cd source-code
make check   # build all examples
make test    # run all test suites
make clean   # remove build output
```

## License

Apache 2.0. Copyright 2016-2026 Mark Watson. All rights reserved.
