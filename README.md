# OCaml AI Book

Source code and examples for the **OCaml AI Book** by Mark Watson.

The examples are OCaml ports of the code from my Haskell book. They cover OCaml language basics, functional patterns, symbolic math, text processing, natural language tagging, RDF and SPARQL, and calling a local LLM.

All code lives under [`source-code/`](source-code/). Each example is its own [dune](https://dune.build/) project with a build, a runnable program, and a test suite.

## Examples

| Directory | What it shows |
|-----------|---------------|
| [`Pure`](source-code/Pure/) | OCaml basics: pattern matching, branching, `let` bindings, `map`, composition, and variant types |
| [`StateMonad`](source-code/StateMonad/) | A small `State` module that threads state through a computation |
| [`SymbolicMath`](source-code/SymbolicMath/) | Symbolic differentiation and integration of single-variable polynomials, with exact rationals |
| [`TextProcessing`](source-code/TextProcessing/) | Clean free text, drop stop words, and read CSV and JSON |
| [`FastTag`](source-code/FastTag/) | A simplified Brill part-of-speech tagger driven by a static lexicon and eight rules |
| [`rdf_sparql`](source-code/rdf_sparql/) | An in-memory RDF store and a small SPARQL-style query engine |
| [`ollama_commandline`](source-code/ollama_commandline/) | A command-line client for a local [Ollama](https://ollama.com/) model |

## Setup

Install OCaml and dune with [opam](https://opam.ocaml.org/), then add the libraries the examples use:

```bash
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest qcheck csv lambdasoup caqti caqti-driver-sqlite3 ctypes owl dream
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
