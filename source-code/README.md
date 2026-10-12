# Examples for "OCaml AI Book" by Mark Watson

These are the OCaml ports of the examples from my Haskell book. Each example lives in its own directory and builds with [dune](https://dune.build/).

## Tooling

Install OCaml and dune with [opam](https://opam.ocaml.org/):

```bash
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest csv lambdasoup caqti caqti-lwt caqti-driver-sqlite3 dream
```

To install only one example's libraries, use its generated `.opam` file:

```bash
cd webchat
opam install . --deps-only --with-test
```

Each `dune-project` declares the example's dependencies; dune regenerates the `.opam` file on every build.

## Build and run one example

```bash
cd pure
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
| Csv | CSV read and write |
| Lambdasoup | HTML scraping with CSS selectors |
| Caqti | SQLite access (linked as `caqti.classic`, which works with Caqti 2.3 and 3.x) |

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
