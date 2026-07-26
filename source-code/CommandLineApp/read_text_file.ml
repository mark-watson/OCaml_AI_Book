(* Read temp.txt and print its contents and its words. *)

let () =
  let path = "temp.txt" in
  if Sys.file_exists path then begin
    let contents = Util.read_file path in
    Printf.printf "%S\n" contents;
    print_endline (Util.show_words (Util.words contents))
  end
  else Printf.printf "Error: file '%s' does not exist.\n" path
