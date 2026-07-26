# SQLite - OCaml

OCaml port of the Haskell `sqlite-simple` example. It opens a SQLite file,
creates a table, lists the tables and their schema, inserts a row, and prints
every row. SQLite is serverless: the library reads and writes an ordinary file
(`test.db`).

## Project layout

```
Database-sqlite/
├── src/db.ml     <- typed Caqti queries and thin wrappers
├── bin/main.ml   <- the demo program
└── test/         <- Alcotest round-trip against a temp database
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

Each run inserts another row into `test.db`; `make clean` deletes the file.

## Notes on the Haskell to OCaml port

- Haskell `sqlite-simple` becomes `caqti` with the `caqti-driver-sqlite3` driver
  and the Lwt backend.
- A Haskell query with a type annotation (`query_ conn sql :: IO [(Int, String)]`)
  becomes a Caqti request that pairs argument and row types with the SQL, for
  example `Caqti_type.(unit ->* t2 int string)`.
- `Only a` for single-column results is unneeded: Caqti returns a bare `string`
  or `int`.
- `withConnection` becomes `Caqti_lwt_unix.with_connection`, which closes the
  handle even on error.
- Results come back as `result` values, threaded with a small `>>=?` operator.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
