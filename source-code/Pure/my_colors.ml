(* A custom variant type with a comparison that orders by name text,
   the OCaml analogue of a hand written Ord instance. *)

type my_colors = Orange | Red | Blue | Green | Silver

let show = function
  | Orange -> "Orange"
  | Red -> "Red"
  | Blue -> "Blue"
  | Green -> "Green"
  | Silver -> "Silver"

(* Order colors alphabetically by their name, not by constructor order. *)
let compare_colors c1 c2 = String.compare (show c1) (show c2)

let () =
  let colors = [ Orange; Red; Blue; Green; Silver ] in
  let sorted = List.sort compare_colors colors in
  print_endline (String.concat " < " (List.map show sorted))
