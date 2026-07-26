open Kg

let tbl_of pairs =
  let t = Hashtbl.create 16 in
  List.iter (fun (k, v) -> Hashtbl.replace t k v) pairs;
  t

let write_tmp suffix content =
  let path = Filename.temp_file "kg" suffix in
  let oc = open_out path in
  output_string oc content;
  close_out oc;
  path

let has = Gen_neo4j_cypher.contains_substr

let test_triple () =
  Alcotest.(check string) "format" "a  b  c .\n" (Gen_triples.generate_triple "a" "b" "c")

let test_category_uri () =
  Alcotest.(check string) "known"
    "<http://knowledgebooks.com/schema/topic/chemistry>"
    (Gen_triples.uri_from_category "chemistry");
  Alcotest.(check string) "unknown" "\"zzz\"" (Gen_triples.uri_from_category "zzz")

let test_meta () =
  let p = write_tmp ".meta" {|{"uri":"<doc1>","similar_docs":["a"]}|} in
  let m = File_utils.read_meta_file p in
  Sys.remove p;
  Alcotest.(check string) "uri" "<doc1>" m.File_utils.uri

let empty_maps () : File_utils.entity_maps =
  {
    people = tbl_of [];
    companies = tbl_of [ ("Apple Computer", "<c1>") ];
    countries = tbl_of [ ("Brazil", "<b1>") ];
    cities = tbl_of [];
    broadcast_networks = tbl_of [];
    political_parties = tbl_of [];
    trade_unions = tbl_of [];
    universities = tbl_of [];
  }

let test_triples_integration () =
  let txt = write_tmp ".txt" "Brazil and Apple Computer are here." in
  let meta = write_tmp ".meta" {|{"uri":"<doc1>","similar_docs":[]}|} in
  let out =
    Gen_triples.text_to_triples ~onegrams:[] ~twograms:[] ~emaps:(empty_maps ())
      txt meta
  in
  Sys.remove txt;
  Sys.remove meta;
  Alcotest.(check bool) "country link" true (has "<b1>" out);
  Alcotest.(check bool) "country name literal" true (has "\"Brazil\"" out);
  Alcotest.(check bool) "company bigram" true (has "<c1>" out)

let test_cypher () =
  Alcotest.(check bool) "prelude has CategoryType" true
    (has "CategoryType" Gen_neo4j_cypher.neo4j_category_node_defs)

let () =
  Alcotest.run "KGCreator"
    [ ( "triples",
        [ Alcotest.test_case "generate_triple" `Quick test_triple;
          Alcotest.test_case "category uri" `Quick test_category_uri;
          Alcotest.test_case "integration" `Quick test_triples_integration ] );
      ("meta", [ Alcotest.test_case "read_meta_file" `Quick test_meta ]);
      ("cypher", [ Alcotest.test_case "node defs" `Quick test_cypher ]) ]
