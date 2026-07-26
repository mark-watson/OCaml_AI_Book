(* Batch process a directory of .txt (plus matching .meta) files into RDF
   triples and Neo4j Cypher. Ported from the Haskell Apis module. *)

let write_file path s =
  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc s)

let list_text_files dir =
  Sys.readdir dir |> Array.to_list |> List.sort compare
  |> List.filter File_utils.is_text_file
  |> List.map (fun f -> Filename.concat dir f)

let meta_of txt = Filename.remove_extension txt ^ ".meta"

let process_files_to_rdf ~onegrams ~twograms ~emaps dir out =
  list_text_files dir
  |> List.map (fun fp ->
         Gen_triples.text_to_triples ~onegrams ~twograms ~emaps fp (meta_of fp))
  |> String.concat ""
  |> write_file out

let process_files_to_neo4j ~onegrams ~twograms ~emaps dir out =
  let body =
    list_text_files dir
    |> List.map (fun fp ->
           Gen_neo4j_cypher.text_to_cypher ~onegrams ~twograms ~emaps fp (meta_of fp))
    |> String.concat ""
  in
  write_file out (Gen_neo4j_cypher.neo4j_category_node_defs ^ body)
