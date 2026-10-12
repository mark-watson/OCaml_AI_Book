# SQLite Databases

This chapter stores and reads data in a SQLite database. SQLite needs no server: the library reads and writes an ordinary file, so it is a fine choice for a local application or a cache. The example is in `source-code/database_sqlite/`, and it uses [Caqti](https://github.com/paurkedal/ocaml-caqti), a library that turns a SQL statement into a typed OCaml value.

Two ideas in this chapter are new and worth your attention: Caqti's typed queries, and Lwt, OCaml's library for asynchronous code. Both come back in the networking and web chapters, so it pays to meet them here on a small example.

## Typed Queries

With Caqti you write each query once as a value that pairs the SQL text with the types of its input and output. The compiler then checks every use against those types. The file `src/db.ml` defines the queries:

```ocaml
open Caqti_request.Infix

let create_table =
  Caqti_type.(unit ->. unit)
    "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, str text)"

let list_tables =
  Caqti_type.(unit ->* string)
    "SELECT name FROM sqlite_master WHERE type='table'"

let insert_row =
  Caqti_type.(string ->. unit) "INSERT INTO test (str) VALUES (?)"

let all_rows =
  Caqti_type.(unit ->* t2 int string) "SELECT id, str FROM test"
```

Read each query as "input type, arrow, output type, SQL." The arrow tells Caqti how many rows to expect: `->.` means the statement returns no rows, and `->*` means it returns zero or more. So:

- `create_table` takes no input (`unit`) and returns nothing. It runs the `CREATE TABLE`.
- `list_tables` takes no input and returns many strings, one table name per row.
- `insert_row` takes a `string` (the value for the `?` placeholder) and returns nothing.
- `all_rows` takes no input and returns many rows, each a pair of an `int` and a `string`, written `t2 int string`.

Because the row type of `all_rows` is `t2 int string`, Caqti hands you back `(int * string)` pairs, already typed. There is no manual column parsing and no chance of reading column two as the wrong type.

## Running a Query

A live database connection is passed as a first-class module: a module packed up as an ordinary value. Each wrapper function unpacks the connection in its parameter and calls a method on it:

```ocaml
let init (module Db : Caqti_lwt.CONNECTION) = Db.exec create_table ()
let tables (module Db : Caqti_lwt.CONNECTION) = Db.collect_list list_tables ()
let insert (module Db : Caqti_lwt.CONNECTION) s = Db.exec insert_row s
let rows (module Db : Caqti_lwt.CONNECTION) = Db.collect_list all_rows ()
```

The parameter `(module Db : Caqti_lwt.CONNECTION)` says "take a value that is a module matching the `CONNECTION` signature, and call it `Db`." First-class modules let Caqti hand you a connection as data, which you then use like a normal module. `Db.exec` runs a statement that returns no rows; `Db.collect_list` runs a query and gathers its rows into a list. Note that `insert` takes the string `s` and passes it as the query's argument.

## Lwt and Threading Results

Every Caqti call returns an Lwt promise of a result. Lwt is OCaml's library for asynchronous code: a value of type `'a Lwt.t` is a computation that will finish later, and `Lwt.bind` chains such computations. On top of that, each database call can succeed with `Ok value` or fail with `Error e`. The driver in `bin/main.ml` combines both with one small operator:

```ocaml
let ( >>=? ) m f =
  Lwt.bind m (function Ok x -> f x | Error e -> Lwt.return (Error e))
```

`m >>=? f` waits for the promise `m`. If it produced `Ok x`, it runs `f x`. If it produced `Error e`, it stops and passes the error along. This threads both the "later" of Lwt and the "might fail" of the result through the whole program, so you write the happy path and the errors take care of themselves:

```ocaml
let program conn =
  Db.init conn >>=? fun () ->
  Db.tables conn >>=? fun tables ->
  print_endline "Table names in database test.db:";
  List.iter (Printf.printf "%S\n") tables;
  Db.schema conn >>=? fun sqls ->
  print_endline "SQL to create table 'test' in database test.db:";
  List.iter (Printf.printf "%S\n") sqls;
  Db.insert conn "test string 2" >>=? fun () ->
  Db.rows conn >>=? fun rows ->
  Printf.printf "number of rows in table 'test': %d\n" (List.length rows);
  print_endline "rows in table 'test':";
  List.iter (fun (id, s) -> Printf.printf "(%d,%S)\n" id s) rows;
  Lwt.return (Ok ())
```

Read it top to bottom: create the table, list the tables, show the schema, insert a row, then count and print the rows. Each step waits for the one before, and any database error short-circuits to the end. The final `Lwt.return (Ok ())` produces the success value the whole chain expects.

## Opening the Connection

The main function names the database with a URI and opens a connection with `with_connection`, which closes the handle even if the program raises:

```ocaml
let () =
  let uri = Uri.of_string "sqlite3:test.db" in
  match Lwt_main.run (Caqti_lwt_unix.with_connection uri program) with
  | Ok () -> ()
  | Error e ->
    prerr_endline (Caqti_error.show e);
    exit 1
```

The URI `sqlite3:test.db` picks the SQLite driver and the file `test.db`. `Caqti_lwt_unix.with_connection` opens the file, runs `program`, and closes it. `Lwt_main.run` starts the Lwt event loop and waits for the whole thing to finish; it is the one place the async code touches the real world. The final `match` prints any error and exits non-zero, so a failure is loud rather than silent.

## Building and Running

The `dune` files list the driver as a dependency. The library needs `caqti.classic` and `caqti-lwt`; the program adds the SQLite driver and the Lwt Unix backend:

```
(executable
 (name main)
 (libraries db caqti.classic caqti-lwt caqti-lwt.unix caqti-driver-sqlite3
   uri lwt.unix))
```

The `.classic` suffix matters. Caqti 3.0 introduced a new API under the plain `caqti` library name and moved the API used in this chapter, built around `Caqti_request` and `Caqti_type`, to `caqti.classic`. Linking `caqti.classic` builds the example with Caqti 2.3 or any 3.x release.

Build and run it:

```bash
cd source-code/database_sqlite
dune build
dune exec ./bin/main.exe
dune runtest
```

Each run adds another row to `test.db`, so the row count grows each time you run it. The program prints the table names, the schema, the row count, and every row. You now have the Caqti pattern: define typed queries once, wrap each in a small function over a first-class connection, and thread the Lwt results with `>>=?`. The same shape scales from this one table to a real schema.
