(* Haskell `main` printed `Red < Green`. With alphabetical ordering "Green"
   sorts before "Red", so Red < Green is false. *)
let () = Printf.printf "%b\n" My_colors.(Red < Green)
