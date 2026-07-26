(* Read temp.txt, catching only the file-system error rather than every
   exception. Haskell narrowed its catch to IOException; here we match the
   Sys_error raised by open_in on a missing or unreadable file. *)

let safe_file_reader path =
  try Util.read_file path
  with Sys_error msg ->
    Printf.printf "Error: %s\n" msg;
    ""

let () =
  let contents = safe_file_reader "temp.txt" in
  Printf.printf "%S\n" contents;
  print_endline (Util.show_words (Util.words contents))
