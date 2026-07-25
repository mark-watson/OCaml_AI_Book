(* Guard-style branching and option values.
   OCaml has no guard syntax, so we use nested if / match. *)

let spaceship n =
  if n < 0 then -1
  else if n = 0 then 0
  else 1

let random_maybe_value n =
  if n mod 2 = 0 then Some n else None

let show_opt = function
  | Some n -> "Some " ^ string_of_int n
  | None -> "None"

let () =
  Printf.printf "%d\n" (spaceship (-100));
  Printf.printf "%d\n" (spaceship 0);
  Printf.printf "%d\n" (spaceship 17);
  print_endline (show_opt (random_maybe_value 1));
  print_endline (show_opt (random_maybe_value 2))
