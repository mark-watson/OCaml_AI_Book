(* Haskell showed `let` with and without `in` inside a do block. OCaml has only
   `let ... in`, so these three examples differ only cosmetically. *)

let rec read_int () =
  print_endline "Enter an integer number:";
  match int_of_string_opt (String.trim (read_line ())) with
  | Some n -> n
  | None ->
    print_endline "Error: invalid integer, please try again.";
    read_int ()

let example1 () =
  let number = read_int () in
  let result = number + 2 in
  Printf.printf "Number plus 2 = %d\n" result

let example2 () = example1 ()

let example3 () =
  let number = read_int () in
  let result = number + 2 in
  print_endline "Result is:";
  Printf.printf "Number plus 2 = %d\n" result

let () =
  example1 ();
  example2 ();
  example3 ()
