(* Tag a sample sentence and print the tokens paired with their POS tags. *)

let show_string_list xs =
  "[" ^ String.concat "," (List.map (Printf.sprintf "%S") xs) ^ "]"

let show_pairs ps =
  "["
  ^ String.concat ","
      (List.map (fun (a, b) -> Printf.sprintf "(%S,%S)" a b) ps)
  ^ "]"

let () =
  let tokens =
    [
      "the"; "dog"; "ran"; "around"; "the"; "tree"; "while"; "the"; "cat";
      "snaked"; "around"; "the"; "trunk"; "while"; "banking"; "to"; "the"; "left";
    ]
  in
  let tags = Fasttag.tag tokens in
  print_endline (show_string_list tags);
  print_endline (show_pairs (List.combine tokens tags))
