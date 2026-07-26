let rec read_int () =
  print_endline "Enter an integer number:";
  match int_of_string_opt (String.trim (read_line ())) with
  | Some n -> n
  | None ->
    print_endline "Error: invalid integer, please try again.";
    read_int ()

let example1 () =
  let number = read_int () in
  Printf.printf "Number plus 2 = %d\n" (number + 2)

(* Haskell main = example1 >> example2 >> example1; example2 was identical to
   example1 apart from `let ... in` styling, so we just run example1 three times. *)
let () =
  example1 ();
  example1 ();
  example1 ()
