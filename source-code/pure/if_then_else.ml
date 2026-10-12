(* if / then / else as an expression *)

let age_to_string age =
  if age < 21 then "minor" else "adult"

let () =
  print_endline (age_to_string 15);
  print_endline (age_to_string 37)
