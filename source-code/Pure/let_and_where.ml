(* let bindings and list comprehensions.
   OCaml has no where clause, so we use let ... in for local bindings. *)

let funny_summation w x y z =
  let bob = w + x in
  let sally = y + z in
  bob + sally

(* Haskell: [(a,b) | a <- [0..5], let b = 10 * a] *)
let test_let_comprehension =
  List.init 6 (fun a -> (a, 10 * a))

let test_where_blocks a =
  let z = a + 2 in
  let q = 2 in
  z * q

let function_with_where n =
  let tenn = 10 * n in
  (n + 1) * tenn

let show_pairs ps =
  "[" ^ String.concat ","
          (List.map (fun (a, b) -> Printf.sprintf "(%d,%d)" a b) ps) ^ "]"

let () =
  Printf.printf "%d\n" (funny_summation 1 2 3 4);
  print_endline "Rigby";
  print_endline (show_pairs test_let_comprehension);
  Printf.printf "%d\n" (test_where_blocks 11);
  Printf.printf "%d\n" (function_with_where 1)
