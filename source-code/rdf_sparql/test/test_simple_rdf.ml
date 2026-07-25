(* Alcotest port of the original HSpec suite. *)

open Simple_rdf

let iri s = IRI s
let lit s = Lit s

let node = Alcotest.testable (fun fmt n -> Format.pp_print_string fmt (format_node n)) ( = )

(* Compare bindings as sorted association lists. *)
let bindings_opt = Alcotest.(option (list (pair string node)))
let to_bl = function None -> None | Some b -> Some (StringMap.bindings b)

let test_graph =
  [
    (iri "Alice", iri "likes", iri "Bob");
    (iri "Alice", iri "likes", iri "Pizza");
    (iri "Bob", iri "likes", iri "Alice");
    (iri "Bob", iri "likes", iri "Pasta");
    (iri "Charlie", iri "likes", iri "Bob");
    (iri "Alice", iri "age", lit "25");
    (iri "Bob", iri "age", lit "28");
  ]

let test_format_node () =
  Alcotest.(check string) "IRI" "<http://example.org>" (format_node (IRI "http://example.org"));
  Alcotest.(check string) "Lit" "\"hello\"" (format_node (Lit "hello"));
  Alcotest.(check string) "BNode" "_:b42" (format_node (BNode 42))

let test_match_node () =
  Alcotest.check bindings_opt "QTerm equal" (Some [])
    (to_bl (match_node StringMap.empty (QTerm (iri "likes")) (iri "likes")));
  Alcotest.check bindings_opt "QTerm differ" None
    (to_bl (match_node StringMap.empty (QTerm (iri "likes")) (iri "hates")));
  Alcotest.check bindings_opt "bind QVar" (Some [ ("x", iri "Alice") ])
    (to_bl (match_node StringMap.empty (QVar "x") (iri "Alice")));
  Alcotest.check bindings_opt "QVar existing matches" (Some [ ("x", iri "Alice") ])
    (to_bl (match_node (StringMap.singleton "x" (iri "Alice")) (QVar "x") (iri "Alice")));
  Alcotest.check bindings_opt "QVar existing differs" None
    (to_bl (match_node (StringMap.singleton "x" (iri "Alice")) (QVar "x") (iri "Bob")))

let test_match_triple () =
  Alcotest.check bindings_opt "concrete match" (Some [])
    (to_bl
       (match_triple StringMap.empty
          (TP (QTerm (iri "Alice"), QTerm (iri "likes"), QTerm (iri "Bob")))
          (iri "Alice", iri "likes", iri "Bob")));
  match
    match_triple StringMap.empty
      (TP (QVar "s", QTerm (iri "likes"), QVar "o"))
      (iri "Alice", iri "likes", iri "Bob")
  with
  | None -> Alcotest.fail "Expected match"
  | Some b ->
      Alcotest.(check (option node)) "s" (Some (iri "Alice")) (StringMap.find_opt "s" b);
      Alcotest.(check (option node)) "o" (Some (iri "Bob")) (StringMap.find_opt "o" b)

let test_evaluate_patterns () =
  Alcotest.(check int) "empty pattern list -> one empty binding" 1
    (List.length (evaluate_patterns test_graph []));
  let pats = [ TP (QVar "s", QTerm (iri "likes"), QVar "o") ] in
  Alcotest.(check int) "five subjects that like someone" 5
    (List.length (evaluate_patterns test_graph (List.rev pats)))

let test_run_query () =
  let q1 =
    { vars = [ "s"; "o" ]; where_clause = [ TP (QVar "s", QTerm (iri "likes"), QVar "o") ] }
  in
  let r1 = run_query test_graph q1 in
  Alcotest.(check int) "likes pairs count" 5 (List.length r1);
  Alcotest.(check bool) "Alice likes Bob" true (List.mem [ iri "Alice"; iri "Bob" ] r1);
  Alcotest.(check bool) "Bob likes Alice" true (List.mem [ iri "Bob"; iri "Alice" ] r1);

  let q2 =
    { vars = [ "who" ]; where_clause = [ TP (QVar "who", QTerm (iri "likes"), QTerm (iri "Bob")) ] }
  in
  let r2 = run_query test_graph q2 in
  Alcotest.(check int) "who likes Bob count" 2 (List.length r2);
  Alcotest.(check bool) "Alice" true (List.mem [ iri "Alice" ] r2);
  Alcotest.(check bool) "Charlie" true (List.mem [ iri "Charlie" ] r2);

  let q3 =
    { vars = [ "who"; "age" ]; where_clause = [ TP (QVar "who", QTerm (iri "age"), QVar "age") ] }
  in
  let r3 = run_query test_graph q3 in
  Alcotest.(check int) "ages count" 2 (List.length r3);
  Alcotest.(check bool) "Alice 25" true (List.mem [ iri "Alice"; lit "25" ] r3);

  let q4 =
    {
      vars = [ "a"; "b" ];
      where_clause =
        [
          TP (QVar "a", QTerm (iri "likes"), QVar "b");
          TP (QVar "b", QTerm (iri "likes"), QVar "a");
        ];
    }
  in
  let r4 = run_query test_graph q4 in
  Alcotest.(check int) "mutual likes count" 2 (List.length r4);

  let q5 =
    { vars = [ "x" ]; where_clause = [ TP (QVar "x", QTerm (iri "hates"), QVar "y") ] }
  in
  Alcotest.(check int) "no matches" 0 (List.length (run_query test_graph q5))

let () =
  Alcotest.run "SimpleRDF"
    [
      ("formatNode", [ Alcotest.test_case "format" `Quick test_format_node ]);
      ("matchNode", [ Alcotest.test_case "match_node" `Quick test_match_node ]);
      ("matchTriple", [ Alcotest.test_case "match_triple" `Quick test_match_triple ]);
      ("evaluatePatterns", [ Alcotest.test_case "eval" `Quick test_evaluate_patterns ]);
      ("runQuery", [ Alcotest.test_case "run_query" `Quick test_run_query ]);
    ]
