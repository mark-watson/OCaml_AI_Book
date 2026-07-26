(* Command-line NLP tool: categorize text, summarize it, and pull out people,
   company, and country names. Loads the TSV corpora from ./data, so run from
   the NlpTool project root. Mirrors the Haskell app/NlpTool.hs. *)

open Nlp

let show_entities es =
  "["
  ^ String.concat ", "
      (List.map (fun (name, uri) -> Printf.sprintf "%s -> %s" name uri) es)
  ^ "]"

let () =
  let onegrams = Nlp_data.load_ngrams "data/category_1gram.tsv" in
  let twograms = Nlp_data.load_ngrams "data/category_2gram.tsv" in
  let people = Nlp_data.load_entity_map "data/people.tsv" in
  let countries = Nlp_data.load_entity_map "data/countries.tsv" in
  let companies = Nlp_data.load_entity_map "data/companies.tsv" in
  let rec loop () =
    print_endline "Enter text (or \"exit\"/\"quit\" to stop):";
    match read_line () with
    | exception End_of_file -> ()
    | "exit" | "quit" -> print_endline "Goodbye."
    | s ->
      let cats = Categorize.best_categories ~onegrams ~twograms (Nlp_utils.split_words s) in
      let best_cat = match cats with (name, _) :: _ -> name | [] -> "" in
      let spwkc = Nlp_utils.split_words_keep_case s in
      Printf.printf "category:\t%s\n" best_cat;
      Printf.printf "summary:\t%s\n" (Summarize.summarize_s ~onegrams ~twograms s);
      Printf.printf "people:\t%s\n" (show_entities (Entities.entity_names people spwkc));
      Printf.printf "companies:\t%s\n"
        (show_entities (Entities.entity_names companies spwkc));
      Printf.printf "countries:\t%s\n"
        (show_entities (Entities.entity_names countries spwkc));
      loop ()
  in
  loop ()
