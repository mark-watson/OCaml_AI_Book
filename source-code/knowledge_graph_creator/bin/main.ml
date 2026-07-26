(* Knowledge graph creator: read a directory of .txt files (each with a matching
   .meta JSON file), and write RDF triples (.n3) and Neo4j Cypher (.cypher).
   Run from the project root so ./data resolves. Mirrors app/Main.hs. *)

open Kg

let () =
  match Array.to_list Sys.argv with
  | [ _; input_dir; output_root ] ->
    let onegrams = Nlp_data.load_ngrams "data/category_1gram.tsv" in
    let twograms = Nlp_data.load_ngrams "data/category_2gram.tsv" in
    let emaps = File_utils.load_entity_maps "data" in
    Apis.process_files_to_rdf ~onegrams ~twograms ~emaps input_dir
      (output_root ^ ".n3");
    Apis.process_files_to_neo4j ~onegrams ~twograms ~emaps input_dir
      (output_root ^ ".cypher");
    Printf.printf "Wrote %s.n3 and %s.cypher\n" output_root output_root
  | _ ->
    prerr_endline "usage: main <input_dir> <output_root>";
    prerr_endline
      "  reads .txt and matching .meta files; writes <root>.n3 and <root>.cypher";
    exit 1
