let sample =
  {|{"head":{"vars":["label"]},
     "results":{"bindings":[
       {"label":{"type":"literal","xml:lang":"en","value":"IBM"}},
       {"label":{"type":"literal","xml:lang":"en","value":"International Business Machines"}}
     ]}}|}

let test_values () =
  let vs = Sparql.values_of_json "label" (Yojson.Safe.from_string sample) in
  Alcotest.(check (list string))
    "labels" [ "IBM"; "International Business Machines" ] vs

let test_uri () =
  let uri = Sparql.query_uri "select * where {?s ?p ?o}" in
  let q = Option.value ~default:"" (Uri.get_query_param uri "format") in
  Alcotest.(check string) "format json" "json" q

let () =
  Alcotest.run "SparqlClient"
    [ ( "decode",
        [ Alcotest.test_case "values" `Quick test_values;
          Alcotest.test_case "uri params" `Quick test_uri ] ) ]
