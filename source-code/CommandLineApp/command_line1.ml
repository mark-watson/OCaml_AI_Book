(* Read lines and echo them upper-cased until the user types exit or quit. *)

let rec loop () =
  print_endline "Enter a line of text for test 1 (or \"exit\"/\"quit\" to stop):";
  match read_line () with
  | exception End_of_file -> print_endline "Goodbye!"
  | ("exit" | "quit") -> print_endline "Goodbye!"
  | s ->
    Printf.printf "As upper case:\t%s\n" (String.uppercase_ascii s);
    loop ()

let () = loop ()
