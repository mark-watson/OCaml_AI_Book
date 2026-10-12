module SS = Set.Make (String)

let file_to_words path =
  Util.read_file path |> String.lowercase_ascii |> Util.words |> SS.of_list

(* Haskell showed three styles (do-notation, >>=, applicative) for the same
   result. OCaml has no IO monad, so they collapse to one direct expression. *)
let common_words f1 f2 =
  SS.elements (SS.inter (file_to_words f1) (file_to_words f2))

let () =
  common_words "text1.txt" "text2.txt" |> Util.show_words |> print_endline
