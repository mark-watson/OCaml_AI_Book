(* Connect to test.db, ensure the table exists, then list tables, show the
   schema, insert a row, and print every row. Mirrors the Haskell sqlite-simple
   example. *)

let ( >>=? ) m f =
  Lwt.bind m (function Ok x -> f x | Error e -> Lwt.return (Error e))

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

let () =
  let uri = Uri.of_string "sqlite3:test.db" in
  match Lwt_main.run (Caqti_lwt_unix.with_connection uri program) with
  | Ok () -> ()
  | Error e ->
    prerr_endline (Caqti_error.show e);
    exit 1
