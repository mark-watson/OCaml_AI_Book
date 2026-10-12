(* Sanity checks for the tagger and its helpers. *)

let test_bigram () =
  Alcotest.(check (list (list int)))
    "sliding window of size 2"
    [ [ 1; 2 ]; [ 2; 3 ]; [ 3; 4 ] ]
    (Fasttag.bigram [ 1; 2; 3; 4 ]);
  Alcotest.(check (list (list int))) "too short" [] (Fasttag.bigram [ 1 ])

let test_tag () =
  let tokens = [ "the"; "dog"; "ran"; "around"; "the"; "tree" ] in
  let tags = Fasttag.tag tokens in
  Alcotest.(check int) "one tag per token" (List.length tokens) (List.length tags);
  (* "the" is a determiner in the lexicon *)
  Alcotest.(check string) "the -> DT" "DT" (List.nth tags 0);
  Alcotest.(check string) "dog -> NN" "NN" (List.nth tags 1)

let test_tag_helper () =
  Alcotest.(check (list string)) "known word" [ "the"; "DT" ] (Fasttag.tag_helper "the");
  Alcotest.(check (list string))
    "unknown word defaults to NN"
    [ "zxqwv"; "NN" ] (Fasttag.tag_helper "zxqwv")

let () =
  Alcotest.run "FastTag"
    [
      ("bigram", [ Alcotest.test_case "bigram" `Quick test_bigram ]);
      ("tag", [ Alcotest.test_case "tag" `Quick test_tag ]);
      ("tagHelper", [ Alcotest.test_case "tag_helper" `Quick test_tag_helper ]);
    ]
