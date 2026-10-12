(* Shared helpers for the impure examples. *)

let read_file path =
  let ic = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () -> really_input_string ic (in_channel_length ic))

(* Split on any whitespace, dropping empty pieces, like Haskell `words`. *)
let words s =
  s
  |> String.map (fun c -> if c = '\t' || c = '\n' || c = '\r' then ' ' else c)
  |> String.split_on_char ' '
  |> List.filter (fun w -> w <> "")

(* Render a string list the way Haskell `show` does: ["a","b"]. *)
let show_words ws =
  "[" ^ String.concat "," (List.map (Printf.sprintf "%S") ws) ^ "]"
