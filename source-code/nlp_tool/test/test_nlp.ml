open Nlp

let tbl_of pairs =
  let t = Hashtbl.create 16 in
  List.iter (fun (k, v) -> Hashtbl.replace t k v) pairs;
  t

let test_split () =
  Alcotest.(check (list string))
    "lowercased, punctuation stripped" [ "the"; "dog"; "ran" ]
    (Nlp_utils.split_words "The dog, ran!")

let test_bigrams () =
  Alcotest.(check (list string))
    "space-joined bigrams" [ "a b"; "b c" ]
    (Nlp_utils.bigram_s [ "a"; "b"; "c" ])

let test_stem () =
  let cases =
    [ ("caresses", "caress"); ("ponies", "poni"); ("running", "run");
      ("happy", "happi"); ("nationalization", "nation") ]
  in
  List.iter
    (fun (input, expected) ->
      Alcotest.(check string) input expected (Stemmer.stem input))
    cases

let test_segment () =
  let s = Sentence.segment "Mr. Jones ran. He won." in
  Alcotest.(check int) "two sentences" 2 (List.length s);
  Alcotest.(check string) "abbrev kept together" "Mr. Jones ran." (List.hd s)

let test_categorize () =
  let onegrams =
    [ ("animals", tbl_of [ ("cat", 2.0); ("dog", 2.0) ]);
      ("tech", tbl_of [ ("computer", 2.0) ]) ]
  in
  let cats = Categorize.best_categories ~onegrams ~twograms:[] [ "cat"; "dog" ] in
  match cats with
  | (name, _) :: _ -> Alcotest.(check string) "best is animals" "animals" name
  | [] -> Alcotest.fail "expected a category"

let test_entities () =
  let m = tbl_of [ ("Brazil", "uri1"); ("United Kingdom", "uri2") ] in
  let found = Entities.entity_names m [ "Brazil"; "United"; "Kingdom" ] in
  Alcotest.(check int) "brazil and united kingdom" 2 (List.length found)

let () =
  Alcotest.run "NlpTool"
    [ ( "utils",
        [ Alcotest.test_case "split_words" `Quick test_split;
          Alcotest.test_case "bigram_s" `Quick test_bigrams ] );
      ("stemmer", [ Alcotest.test_case "stem" `Quick test_stem ]);
      ("sentence", [ Alcotest.test_case "segment" `Quick test_segment ]);
      ("categorize", [ Alcotest.test_case "best" `Quick test_categorize ]);
      ("entities", [ Alcotest.test_case "names" `Quick test_entities ]) ]
