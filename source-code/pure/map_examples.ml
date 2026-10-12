(* Association maps. OCaml's standard Map is a functor over a key module. *)

module StringMap = Map.Make (String)

let a_test_map =
  StringMap.of_seq (List.to_seq [ ("height", 120); ("weight", 15) ])

let get_numeric_value key a_map =
  match StringMap.find_opt key a_map with
  | Some v -> v
  | None -> -1

let () =
  Printf.printf "%d\n" (get_numeric_value "height" a_test_map);
  Printf.printf "%d\n" (get_numeric_value "age" a_test_map)
