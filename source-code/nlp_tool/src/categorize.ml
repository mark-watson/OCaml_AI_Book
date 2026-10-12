(* Text categorization by scored word/bigram lists, ported from the Haskell
   Categorize module. Scores against the raw and stemmed 1-gram and 2-gram
   tables, then normalizes to probabilities. *)

let take n lst = List.filteri (fun i _ -> i < n) lst

let score_cat words (m : (string, float) Hashtbl.t) =
  List.fold_left
    (fun acc w -> acc +. Option.value ~default:0. (Hashtbl.find_opt m w))
    0. words

let stem_words_in_string s =
  Nlp_utils.split_words s |> List.map Stemmer.stem |> String.concat " "

let stem_ngrams (ngrams : Nlp_data.ngrams) : Nlp_data.ngrams =
  List.map
    (fun (cat, m) ->
      let out = Hashtbl.create (Hashtbl.length m) in
      Hashtbl.iter (fun k v -> Hashtbl.replace out (stem_words_in_string k) v) m;
      (cat, out))
    ngrams

(* For each category keep those scoring over 0.9, sorted high to low. *)
let best_categories_helper words (ngrams : Nlp_data.ngrams) =
  ngrams
  |> List.map (fun (cat, m) -> (cat, score_cat words m))
  |> List.filter (fun (_, s) -> s > 0.9)
  |> List.sort (fun (_, a) (_, b) -> compare b a)

let merge_sum lists =
  let tbl = Hashtbl.create 32 in
  List.iter
    (List.iter (fun (k, v) ->
         Hashtbl.replace tbl k (v +. Option.value ~default:0. (Hashtbl.find_opt tbl k))))
    lists;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) tbl []

let best_categories ~onegrams ~twograms words =
  let stem1 = stem_ngrams onegrams and stem2 = stem_ngrams twograms in
  let bigrams = Nlp_utils.bigram_s words in
  let b1 = take 3 (best_categories_helper words onegrams) in
  let b2 = take 3 (best_categories_helper bigrams twograms) in
  let b1s = take 3 (best_categories_helper words stem1) in
  let b2s = take 3 (best_categories_helper bigrams stem2) in
  let non_normalized =
    merge_sum [ b1; b2; b1s; b2s ]
    |> List.sort (fun (_, a) (_, b) -> compare b a)
  in
  let total = List.fold_left (fun a (_, v) -> a +. v) 0. non_normalized in
  List.map
    (fun (name, v) -> (name, if total = 0. then 0. else v /. total))
    non_normalized
