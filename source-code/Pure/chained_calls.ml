(* Function composition and application.
   Haskell's ($) is plain application in OCaml; (.) is the |> or @@ operators. *)

let show_int_list xs =
  "[" ^ String.concat "," (List.map string_of_int xs) ^ "]"

let double_odd_elements =
  List.map (fun x -> if x mod 2 = 0 then x else 2 * x)

let times10_elements = List.map (fun x -> x * 10)

let () =
  print_endline (show_int_list (double_odd_elements [0; 1; 2; 3; 4; 5; 6; 7; 8]));
  let a_list = [0; 1; 2; 3; 4; 5] in
  (* @@ is right-associative application, like Haskell's ($) *)
  let new_list = times10_elements @@ double_odd_elements a_list in
  print_endline (show_int_list new_list);
  (* compose the two functions, apply g first then f *)
  let compose f g x = f (g x) in
  let new_list2 = (compose times10_elements double_odd_elements) a_list in
  print_endline (show_int_list new_list2)
