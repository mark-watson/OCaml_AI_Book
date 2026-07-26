(* SQLite access with Caqti. The Haskell version used sqlite-simple; Caqti gives
   OCaml the same "prepared query as a typed value" style.

   Each query below pairs an argument type and a result type with SQL text:
   [->.] means "no result rows", [->*] means "zero or more rows". *)

open Caqti_request.Infix

let create_table =
  Caqti_type.(unit ->. unit)
    "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, str text)"

let list_tables =
  Caqti_type.(unit ->* string)
    "SELECT name FROM sqlite_master WHERE type='table'"

let table_sql =
  Caqti_type.(unit ->* string)
    "SELECT sql FROM sqlite_master WHERE type='table' AND name='test'"

let insert_row =
  Caqti_type.(string ->. unit) "INSERT INTO test (str) VALUES (?)"

let all_rows =
  Caqti_type.(unit ->* t2 int string) "SELECT id, str FROM test"

let init (module Db : Caqti_lwt.CONNECTION) = Db.exec create_table ()
let tables (module Db : Caqti_lwt.CONNECTION) = Db.collect_list list_tables ()
let schema (module Db : Caqti_lwt.CONNECTION) = Db.collect_list table_sql ()
let insert (module Db : Caqti_lwt.CONNECTION) s = Db.exec insert_row s
let rows (module Db : Caqti_lwt.CONNECTION) = Db.collect_list all_rows ()
