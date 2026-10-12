type t = Orange | Red | Blue | Green | Silver

let show = function
  | Orange -> "Orange"
  | Red -> "Red"
  | Blue -> "Blue"
  | Green -> "Green"
  | Silver -> "Silver"

(* Custom order: alphabetical by constructor name, matching the Haskell
   `instance Ord MyColors where compare c1 c2 = compare (show c1) (show c2)`. *)
let compare a b = String.compare (show a) (show b)

let equal a b = compare a b = 0
let ( < ) a b = compare a b < 0
let ( > ) a b = compare a b > 0
