# OCaml AI Book

Source code and examples for the **OCaml AI Book** by Mark Watson.

The examples are OCaml ports of the code from my Haskell book. They cover OCaml language basics, functional patterns, symbolic math, text processing and NLP, RDF and SPARQL, web and database access, LLM and search clients, and three games (blackjack, bridge, and Go).

All code lives under [`source-code/`](source-code/). Each example is its own [dune](https://dune.build/) project with a build, a runnable program, and a test suite.

## Examples

### Language and functional basics

| Directory | What it shows |
|-----------|---------------|
| [`Pure`](source-code/Pure/) | Pattern matching, branching, `let` bindings, `map`, composition, variant types |
| [`Testing`](source-code/Testing/) | Unit testing with Alcotest and a custom ordering |
| [`ImPure`](source-code/ImPure/) | I/O, reading files, and set intersection |
| [`CommandLineApp`](source-code/CommandLineApp/) | Command-line I/O, file handling, a guessing game |
| [`StateMonad`](source-code/StateMonad/) | A small `State` module that threads state through a computation |
| [`debugging`](source-code/debugging/) | Trace-style debugging with a lazy prime sieve |
| [`Timers`](source-code/Timers/) | Timing and a `SIGALRM` timeout |

### Math, text, and NLP

| Directory | What it shows |
|-----------|---------------|
| [`SymbolicMath`](source-code/SymbolicMath/) | Symbolic differentiation and integration, with exact rationals |
| [`TextProcessing`](source-code/TextProcessing/) | Clean free text, drop stop words, read CSV and JSON |
| [`FastTag`](source-code/FastTag/) | A simplified Brill part-of-speech tagger |
| [`NlpTool`](source-code/NlpTool/) | Categorize, summarize, detect entities; Porter stemmer and sentence segmenter |
| [`knowledge_graph_creator`](source-code/knowledge_graph_creator/) | Generate RDF triples and Neo4j Cypher from text files |
| [`dataframe_example`](source-code/dataframe_example/) | A small dataframe over the `csv` library |

### Web, data, and services

| Directory | What it shows |
|-----------|---------------|
| [`WebScraping`](source-code/WebScraping/) | HTML scraping with lambdasoup and cohttp |
| [`Database-sqlite`](source-code/Database-sqlite/) | SQLite access with Caqti |
| [`rdf_sparql`](source-code/rdf_sparql/) | An in-memory RDF store and SPARQL-style query engine |
| [`SparqlClient`](source-code/SparqlClient/) | DBpedia SPARQL queries over HTTP |
| [`ClientServer`](source-code/ClientServer/) | A TCP client and server with Lwt sockets |
| [`webchat`](source-code/webchat/) | A Dream chat app backed by Gemini |
| [`webview`](source-code/webview/) | Dream "web view" apps (counter, hello) with a JS bridge |

### LLM and search clients

| Directory | What it shows |
|-----------|---------------|
| [`ollama_commandline`](source-code/ollama_commandline/) | A command-line client for a local [Ollama](https://ollama.com/) model |
| [`OpenAiApiClient`](source-code/OpenAiApiClient/) | OpenAI chat completions |
| [`gemini_commandline`](source-code/gemini_commandline/) | Gemini text generation and entity extraction |
| [`BraveSearch`](source-code/BraveSearch/) | The Brave Search API |

### Games

| Directory | What it shows |
|-----------|---------------|
| [`Blackjack`](source-code/Blackjack/) | Console blackjack with a card engine |
| [`Bridge_game`](source-code/Bridge_game/) | A contract bridge engine with AI bidding and play |
| [`Bridge_webkit`](source-code/Bridge_webkit/) | A Dream web UI over the bridge engine |
| [`Go_playing_program`](source-code/Go_playing_program/) | A Go board engine (captures, ko, scoring) with a self-play agent |

## Setup

Install OCaml and dune with [opam](https://opam.ocaml.org/), then add the libraries the examples use:

```bash
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest csv lambdasoup caqti caqti-lwt caqti-driver-sqlite3 dream
```

## Build and run one example

```bash
cd source-code/Pure
dune build
dune exec ./simple.exe
dune runtest
```

Each example directory has its own `README.md` with the exact commands to build, run, and test it.

## Build and test everything

The [`source-code/Makefile`](source-code/Makefile) recurses into every example:

```bash
cd source-code
make check   # build all examples
make test    # run all test suites
make clean   # remove build output
```

## License

Apache 2.0. Copyright 2016-2026 Mark Watson. All rights reserved.
