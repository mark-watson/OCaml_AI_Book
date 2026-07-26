open Bwk
open Bwk.Types

let test_parse () =
  Alcotest.(check bool) "pass" true (Parsing.parse_bid_input " pass " = Some Pass);
  Alcotest.(check bool) "1H" true
    (Parsing.parse_bid_input "1H" = Some (Suit_bid (1, Suit_strain Hearts)));
  Alcotest.(check bool) "2NT" true
    (Parsing.parse_bid_input "2NT" = Some (Suit_bid (2, No_trump)));
  Alcotest.(check bool) "x is double" true
    (Parsing.parse_bid_input "x" = Some Double_bid);
  Alcotest.(check bool) "junk" true (Parsing.parse_bid_input "zzz" = None)

let test_payload () =
  let gs = Engine.new_game North Engine.Vul_none South 123 in
  let json = Payload.make_payload gs Scoring.new_rubber_state 1 (`List []) in
  let open Yojson.Safe.Util in
  Alcotest.(check string) "phase" "Bidding" (json |> member "phase" |> to_string);
  Alcotest.(check string) "human" "South" (json |> member "humanPlayer" |> to_string);
  let north = json |> member "hands" |> member "hlNorth" |> to_list in
  Alcotest.(check int) "north has 13 cards" 13 (List.length north)

let () =
  Alcotest.run "Bridge_webkit"
    [ ("parsing", [ Alcotest.test_case "parse_bid_input" `Quick test_parse ]);
      ("payload", [ Alcotest.test_case "make_payload" `Quick test_payload ]) ]
