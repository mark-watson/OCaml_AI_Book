(* match expression, the OCaml form of Haskell case *)

let number_opinion n =
  match n with
  | 0 -> "Too low"
  | 1 -> "just right"
  | _ -> "OK, that is a number"

let () =
  print_endline (number_opinion 0);
  print_endline (number_opinion 1);
  print_endline (number_opinion 2)
