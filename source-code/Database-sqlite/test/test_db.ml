let ( >>=? ) m f =
  Lwt.bind m (function Ok x -> f x | Error e -> Lwt.return (Error e))

(* Create a fresh temp database, insert one row, read it back. *)
let roundtrip () =
  let tmp = Filename.temp_file "caqti_test" ".db" in
  let uri = Uri.of_string ("sqlite3:" ^ tmp) in
  let prog conn =
    Db.init conn >>=? fun () ->
    Db.insert conn "hello" >>=? fun () ->
    Db.rows conn >>=? fun rows -> Lwt.return (Ok rows)
  in
  let result = Lwt_main.run (Caqti_lwt_unix.with_connection uri prog) in
  Sys.remove tmp;
  match result with
  | Ok rows ->
    Alcotest.(check int) "one row" 1 (List.length rows);
    Alcotest.(check string) "value round-trips" "hello" (snd (List.hd rows))
  | Error e -> Alcotest.failf "caqti error: %s" (Caqti_error.show e)

let () =
  Alcotest.run "Database-sqlite"
    [ ("roundtrip", [ Alcotest.test_case "insert and read back" `Quick roundtrip ]) ]
