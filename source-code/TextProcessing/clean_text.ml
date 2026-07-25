(* Clean up free text: separate punctuation, drop noise characters, and
   remove stop words. A pure port of the Haskell CleanText example. *)

let noise_characters =
  [ '['; ']'; '{'; '}'; '\n'; '\t'; '&'; '^'; '@'; '%'; '$'; '#' ]

let substitute_noise_characters s =
  String.map (fun c -> if List.mem c noise_characters then ' ' else c) s

(* Replace every occurrence of [old_s] with [new_s]. OCaml has no String.replace. *)
let replace_str old_s new_s s =
  let ol = String.length old_s in
  if ol = 0 then s
  else begin
    let buf = Buffer.create (String.length s) in
    let n = String.length s in
    let i = ref 0 in
    while !i < n do
      if !i + ol <= n && String.sub s !i ol = old_s then begin
        Buffer.add_string buf new_s;
        i := !i + ol
      end
      else begin
        Buffer.add_char buf s.[!i];
        incr i
      end
    done;
    Buffer.contents buf
  end

let clean_text s =
  s
  |> replace_str ";" " ; "
  |> replace_str "," " , "
  |> replace_str "." " . "
  |> substitute_noise_characters
  |> String.split_on_char ' '
  |> List.filter (fun x -> String.length x > 0)
  |> String.concat " "

let stop_words = [ "a"; "the"; "that"; "of"; "an"; "and" ]

let remove_stop_words s =
  String.split_on_char ' ' s
  |> List.filter (fun x -> x <> "")
  |> List.filter (fun x -> not (List.mem (String.lowercase_ascii x) stop_words))
  |> String.concat " "

let () =
  let ct =
    clean_text "The[]@] cat, and all the dogs, escaped&^. They were caught."
  in
  Printf.printf "%S\n" ct;
  let nn = remove_stop_words ct in
  Printf.printf "%S\n" nn
