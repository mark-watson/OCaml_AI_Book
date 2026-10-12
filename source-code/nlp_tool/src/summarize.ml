(* Extractive summarization, ported from the Haskell Summarize module. It scores
   each sentence by how well its words fit the document's best categories, then
   returns the highest-scoring couple of sentences. *)

let safe_lookup key alist = Option.value ~default:0. (List.assoc_opt key alist)

let score_sentence_helper words (m : (string, float) Hashtbl.t) =
  List.fold_left
    (fun acc w -> acc +. Option.value ~default:0. (Hashtbl.find_opt m w))
    0. words

let score_for_sentence words (cat_maps : Nlp_data.ngrams) best_cats =
  List.fold_left
    (fun acc (cat, m) ->
      acc +. (safe_lookup cat best_cats *. score_sentence_helper words m))
    0. cat_maps

let merge_pairs a b =
  let tbl = Hashtbl.create 16 in
  let add (k, v) =
    Hashtbl.replace tbl k (v +. Option.value ~default:0. (Hashtbl.find_opt tbl k))
  in
  List.iter add a;
  List.iter add b;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) tbl []

let summarize ~onegrams ~twograms s =
  let words = Nlp_utils.split_words (Nlp_utils.clean_text s) in
  let best_cats = Categorize.best_categories ~onegrams ~twograms words in
  let sentences = Sentence.segment s in
  let result1 =
    List.map
      (fun sent ->
        (sent, score_for_sentence (Nlp_utils.split_words sent) onegrams best_cats))
      sentences
  in
  (* The Haskell version unioned result1 with itself here (a typo for result2);
     using result2 lets the 2-gram scores actually contribute. *)
  let result2 =
    List.map
      (fun sent ->
        ( sent,
          score_for_sentence
            (Nlp_utils.bigram_s (Nlp_utils.split_words sent))
            twograms best_cats ))
      sentences
  in
  let merged =
    merge_pairs result1 result2 |> List.filter (fun (_, v) -> v > 0.05)
  in
  let tier t = List.filter (fun (_, v) -> v > t) merged in
  let exactly_two xs = List.length xs = 2 in
  let rec cascade = function
    | t :: rest ->
      let c = tier t in
      if exactly_two c then c else cascade rest
    | [] ->
      if List.length merged < 3 then merged
      else ( match merged with a :: b :: _ -> [ a; b ] | _ -> merged)
  in
  cascade [ 10.; 7.; 4.; 3.; 2.; 1.; 0.5 ]

let drop_last s =
  if s = "" then "" else String.sub s 0 (String.length s - 1)

let summarize_s ~onegrams ~twograms s =
  let parts = summarize ~onegrams ~twograms s in
  let a =
    List.fold_left (fun acc (sent, _) -> acc ^ sent ^ " ") "" parts
    |> Nlp_utils.replace_all "\n" " "
    |> Nlp_utils.replace_all "\"" "'"
  in
  if a <> "" then drop_last a
  else
    match Sentence.segment s with
    | x :: y :: _ -> drop_last (x ^ y)
    | [ x ] -> drop_last x
    | [] -> ""
