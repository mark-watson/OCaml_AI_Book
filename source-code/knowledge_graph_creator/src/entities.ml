(* Entity detection: look up 1-, 2-, and 3-grams of the (case-preserved) words
   in a name -> URI map. Ported from the Haskell Entities module. *)

let entity_names (entity_map : (string, string) Hashtbl.t) words =
  let ngrams =
    words @ Nlp_utils.bigram_s words @ Nlp_utils.trigram_s words
  in
  ngrams
  |> List.filter_map (fun ng ->
         match Hashtbl.find_opt entity_map ng with
         | Some uri -> Some (ng, uri)
         | None -> None)
  |> List.sort_uniq compare
