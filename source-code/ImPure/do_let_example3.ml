(* Haskell: example3 = putStrLn ... >> getLine; example4 parses and prints;
   main = example3 >>= example4. In OCaml this is plain function application. *)

let prompt_line () =
  print_endline "Enter an integer number:";
  read_line ()

let handle mv =
  match int_of_string_opt (String.trim mv) with
  | None -> print_endline "Error: invalid integer."
  | Some n -> Printf.printf "Number plus 2 = %d\n" (n + 2)

let () = handle (prompt_line ())
