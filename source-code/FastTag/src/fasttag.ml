(* A simplified Brill part-of-speech tagger. It assigns an initial tag from a
   static lexicon, then applies transformation rules to fix common cases.
   Based on Eric Brill's rule-based approach. *)

(* Parse the embedded lexicon (word<TAB>tag per line) into a hash table once. *)
let lexicon : (string, string) Hashtbl.t =
  let tbl = Hashtbl.create 131072 in
  List.iter
    (fun line ->
      match String.index_opt line '\t' with
      | Some i ->
          let word = String.sub line 0 i in
          let tag = String.sub line (i + 1) (String.length line - i - 1) in
          Hashtbl.replace tbl word tag
      | None -> ())
    (String.split_on_char '\n' Lexicon_data.data);
  tbl

(* Sliding window of size 2. *)
let rec bigram = function
  | [] | [ _ ] -> []
  | x :: (y :: _ as rest) -> [ x; y ] :: bigram rest

let contains_substring word sub =
  let wl = String.length word and sl = String.length sub in
  if sl = 0 then true
  else
    let rec loop i =
      if i + sl > wl then false
      else if String.sub word i sl = sub then true
      else loop (i + 1)
    in
    loop 0

(* Apply the Brill transformation rules to bigrams of [token; tag] pairs. *)
let fix_tags twogram_list =
  List.map
    (fun pair ->
      match pair with
      | [ [ last_tok; last_tag ]; [ cur_tok; cur_tag ] ] ->
          let starts p = String.starts_with ~prefix:p cur_tag in
          let ends s = String.ends_with ~suffix:s cur_tok in
          let first_is_n = String.length cur_tag > 0 && cur_tag.[0] = 'N' in
          (* rule 1: DT, {VBD | VB | VBP} -> DT, NN *)
          if last_tag = "DT" && (cur_tag = "VBD" || cur_tag = "VB" || cur_tag = "VBP")
          then "NN"
            (* rule 2: noun -> number (CD) if the word contains "." *)
          else if first_is_n && contains_substring cur_tok "." then "CD"
            (* rule 3: noun -> past participle if the word ends with "ed" *)
          else if first_is_n && ends "ed" then "VBN"
            (* rule 4: any type -> adverb if it ends in "ly" *)
          else if ends "ly" then "RB"
            (* rule 5: common noun -> adjective if it ends with "al" *)
          else if starts "NN" && ends "al" then "JJ"
            (* rule 6: noun -> verb if the preceding word is "would" *)
          else if starts "NN" && String.lowercase_ascii last_tok = "would" then "VB"
            (* rule 7: common noun -> plural common noun if it ends with "s" *)
          else if starts "NN" && ends "s" then "NNS"
            (* rule 8: common noun -> gerund if it ends with "ing" *)
          else if starts "NN" && ends "ing" then "VBG"
          else cur_tag
      | _ -> failwith "fix_tags: expected a bigram of [token; tag] pairs")
    twogram_list

let tag_helper token =
  match Hashtbl.find_opt lexicon token with
  | Some tag when tag <> "" -> [ token; tag ]
  | _ -> [ token; "NN" ]

let substitute tks = bigram (List.map tag_helper tks)

(* Prepend an empty token so the first real token has a predecessor. *)
let tag tokens = fix_tags (substitute ("" :: tokens))
