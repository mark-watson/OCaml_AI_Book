(* Build Neo4j Cypher CREATE statements from a text file and its .meta file.
   Ported from the Haskell GenNeo4jCypher module. *)

let contains_substr sub s =
  let ls = String.length s and lsub = String.length sub in
  let rec go i = i + lsub <= ls && (String.sub s i lsub = sub || go (i + 1)) in
  lsub = 0 || go 0

let repl = function '-' | '/' | '.' -> '_' | c -> c

let filter_chars s =
  String.to_seq s
  |> Seq.filter (fun c -> c <> '?' && c <> '=' && c <> '<' && c <> '>')
  |> String.of_seq

let strip_scheme uri =
  uri |> Nlp_utils.replace_all "https://" "" |> Nlp_utils.replace_all "http://" ""

(* One CategoryType node per known category. *)
let neo4j_category_node_defs =
  Gen_triples.category_to_uri_map
  |> List.map (fun (c, _) ->
         Printf.sprintf "CREATE (%s:CategoryType {name:\"%s\"})\n" c c)
  |> String.concat ""
  |> Nlp_utils.replace_all "/" "_"

let create_neo4j_node uri =
  let node_type = if contains_substr "dbpedia" uri then "DbPedia" else "News" in
  let name =
    String.map repl (filter_chars (strip_scheme uri))
    ^ "_" ^ String.lowercase_ascii node_type
  in
  let new_node =
    Printf.sprintf "CREATE (%s:%s {name:\"%s\", uri:\"%s\"})\n" name node_type
      (Nlp_utils.replace_all " " "_" name)
      uri
  in
  (name, new_node)

let create_neo4j_link node1 link_name node2 =
  Printf.sprintf "CREATE (%s)-[:%s]->(%s)\n" node1 link_name node2

let create_summary_node uri summary =
  let name = "summary_of_" ^ String.map repl (filter_chars (strip_scheme uri)) in
  Printf.sprintf "CREATE (%s:Summary {name:\"%s\", uri:\"%s\", summary:\"%s\"})\n"
    name name uri summary

let create_entity_node (name, uri) =
  Printf.sprintf "CREATE (%s:Entity {name:\"%s\", uri:\"%s\"})\n"
    (Nlp_utils.replace_all " " "_" name)
    name uri

let create_contains_entity relation_name source (name, uri) =
  create_entity_node (name, uri)
  ^ create_neo4j_link source relation_name (Nlp_utils.replace_all " " "_" name)

let entity_node_helper relation_name node_name pairs =
  String.concat ""
    (List.map (create_contains_entity relation_name node_name) pairs)

let text_to_cypher ~onegrams ~twograms ~(emaps : File_utils.entity_maps)
    file_path meta_file_path =
  let word_tokens = File_utils.file_to_word_tokens file_path in
  let contents = File_utils.file_to_string file_path in
  let meta = File_utils.read_meta_file meta_file_path in
  let names m = Entities.entity_names m word_tokens in
  let summary = Summarize.summarize_s ~onegrams ~twograms contents in
  let cats = Categorize.best_categories ~onegrams ~twograms word_tokens in
  let filtered = List.filter (fun (_n, v) -> v > 0.3) cats |> List.map fst in
  let node1_name, node1 = create_neo4j_node meta.File_utils.uri in
  let summary1 = create_summary_node meta.File_utils.uri summary in
  let category1 =
    String.concat ""
      (List.map (fun c -> create_neo4j_link node1_name "Category" c) filtered)
  in
  let block relation m = entity_node_helper relation node1_name (names m) in
  String.concat ""
    [ node1; summary1; category1;
      block "ContainsPersonDbPediaLink" emaps.people;
      block "ContainsCompanyDbPediaLink" emaps.companies;
      block "ContainsCountryDbPediaLink" emaps.countries;
      block "ContainsCityDbPediaLink" emaps.cities;
      block "ContainsBroadcastNetworkDbPediaLink" emaps.broadcast_networks;
      block "ContainsPoliticalPartyDbPediaLink" emaps.political_parties;
      block "ContainsTradeUnionDbPediaLink" emaps.trade_unions;
      block "ContainsUniversityDbPediaLink" emaps.universities ]
