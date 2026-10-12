let file_to_words path = Util.words (Util.read_file path)

let () =
  let file = "text1.txt" in
  if Sys.file_exists file then begin
    let ws = file_to_words file in
    print_endline (Util.show_words (List.rev ws));
    (* Haskell used `fmap reverse` over the IO action; here we map List.rev over
       the list the read produced. *)
    let ws2 = List.rev (file_to_words file) in
    print_endline (Util.show_words ws2)
  end
  else Printf.printf "Error: file '%s' not found.\n" file
