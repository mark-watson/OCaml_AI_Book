(* Like command_line1, but also append each line to temp.txt. *)

let append_file path s =
  let oc = open_out_gen [ Open_append; Open_creat ] 0o644 path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc s)

let rec loop () =
  print_endline "Enter a line of text for test 2 (or \"exit\"/\"quit\" to stop):";
  match read_line () with
  | exception End_of_file -> print_endline "Goodbye!"
  | ("exit" | "quit") -> print_endline "Goodbye!"
  | s ->
    Printf.printf "As upper case:\t%s\n" (String.uppercase_ascii s);
    append_file "temp.txt" (s ^ "\n");
    loop ()

let () = loop ()
