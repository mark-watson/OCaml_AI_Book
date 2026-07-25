# Examples for "OCaml AI Book" by Mark Watson

These are the OCaml ports of the examples from my Haskell book. Each example lives in its own directory and builds with [dune](https://dune.build/).

## Tooling

Install OCaml and dune with [opam](https://opam.ocaml.org/):

```bash
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest qcheck csv lambdasoup caqti caqti-driver-sqlite3 ctypes owl dream
```

## Build and run one example

```bash
cd Pure
dune build
dune exec ./simple.exe
```

Run the tests for an example:

```bash
dune runtest
```

## Libraries used

| Library | Use |
|---------|-----|
| Yojson | JSON parsing and printing |
| Cohttp + Lwt | HTTP client for REST and LLM APIs |
| Dream | Web apps and REST servers |
| Alcotest | Unit tests |
| QCheck | Property tests for pure rule engines |
| Csv | CSV read and write |
| Lambdasoup | HTML scraping with CSS selectors |
| Caqti | SQLite and PostgreSQL access |
| Owl | Numerical arrays and dataframes |
| Ctypes | C library bindings |

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
