(* Guess a number between 1 and 4. The target is chosen at random. *)

type game_state = { number_to_guess : int; num_tries : int }

let rec game_loop gs =
  print_endline "Enter a number:";
  match int_of_string_opt (String.trim (read_line ())) with
  | None ->
    print_endline "Invalid input, please enter a number.";
    game_loop gs
  | Some n ->
    if n = gs.number_to_guess then gs
    else game_loop { gs with num_tries = gs.num_tries + 1 }

let () =
  Random.self_init ();
  let gs = { number_to_guess = Random.int 4 + 1; num_tries = 1 } in
  print_endline "Guess a number between 1 and 4";
  let final = game_loop gs in
  Printf.printf "Correct after %d tries.\n" final.num_tries
