open Bridge
open Bridge.Types

let card suit rank = { suit; rank }

let test_deck () =
  Alcotest.(check int) "52 cards" 52 (List.length Cards.make_deck)

let test_hcp () =
  Alcotest.(check int) "ace" 4 (Cards.card_hcp (card Spades Ace));
  Alcotest.(check int) "king" 3 (Cards.card_hcp (card Hearts King));
  Alcotest.(check int) "queen" 2 (Cards.card_hcp (card Diamonds Queen));
  Alcotest.(check int) "jack" 1 (Cards.card_hcp (card Clubs Jack));
  Alcotest.(check int) "two" 0 (Cards.card_hcp (card Spades R2));
  let hand = [ card Spades Ace; card Hearts King; card Diamonds Queen; card Clubs Jack ] in
  Alcotest.(check int) "hand hcp" 10 (Cards.hand_hcp hand)

let test_sort () =
  let hand = [ card Hearts R2; card Spades Ace; card Hearts King ] in
  Alcotest.(check bool) "spade ace first" true
    (List.hd (Cards.sort_hand hand) = card Spades Ace)

let test_balanced () =
  let balanced =
    [ card Spades R2; card Spades R3; card Spades R4; card Spades R5;
      card Hearts R2; card Hearts R3; card Hearts R4;
      card Diamonds R2; card Diamonds R3; card Diamonds R4;
      card Clubs R2; card Clubs R3; card Clubs R4 ]
  in
  Alcotest.(check bool) "4333 is balanced" true (Cards.is_balanced balanced)

let test_bidding_complete () =
  Alcotest.(check bool) "four passes" true
    (Bidding.bidding_complete
       [ (North, Pass); (East, Pass); (South, Pass); (West, Pass) ]);
  Alcotest.(check bool) "three passes after suit bid" true
    (Bidding.bidding_complete
       [ (West, Pass); (South, Pass); (East, Pass);
         (North, Suit_bid (1, Suit_strain Hearts)) ]);
  Alcotest.(check bool) "two passes not complete" false
    (Bidding.bidding_complete
       [ (North, Suit_bid (1, Suit_strain Hearts)); (East, Pass); (South, Pass) ])

let test_bid_index () =
  Alcotest.(check (option int)) "1C" (Some 0) (Bidding.bid_index (Suit_bid (1, Suit_strain Clubs)));
  Alcotest.(check (option int)) "1D" (Some 1) (Bidding.bid_index (Suit_bid (1, Suit_strain Diamonds)));
  Alcotest.(check (option int)) "1NT" (Some 4) (Bidding.bid_index (Suit_bid (1, No_trump)));
  Alcotest.(check (option int)) "2C" (Some 5) (Bidding.bid_index (Suit_bid (2, Suit_strain Clubs)));
  Alcotest.(check (option int)) "Pass" None (Bidding.bid_index Pass)

let test_opening_1nt () =
  let hand =
    [ card Spades Ace; card Spades King; card Spades R3; card Spades R4;
      card Hearts Queen; card Hearts Jack; card Hearts R2;
      card Diamonds King; card Diamonds R2; card Diamonds R3;
      card Clubs Queen; card Clubs R2; card Clubs R3 ]
  in
  Alcotest.(check bool) "15-17 balanced opens 1NT" true
    (Bidding.ai_opening_bid hand = Some (Suit_bid (1, No_trump)))

let test_scoring () =
  Alcotest.(check int) "clubs trick value" 20 (Scoring.trick_value (Suit_strain Clubs) 0);
  Alcotest.(check int) "hearts trick value" 30 (Scoring.trick_value (Suit_strain Hearts) 0);
  Alcotest.(check int) "1NT contract score" 40 (Scoring.contract_trick_score 1 No_trump 0);
  Alcotest.(check int) "1H contract score" 30
    (Scoring.contract_trick_score 1 (Suit_strain Hearts) 0)

let () =
  Alcotest.run "Bridge"
    [ ( "cards",
        [ Alcotest.test_case "deck" `Quick test_deck;
          Alcotest.test_case "hcp" `Quick test_hcp;
          Alcotest.test_case "sort" `Quick test_sort;
          Alcotest.test_case "balanced" `Quick test_balanced ] );
      ( "bidding",
        [ Alcotest.test_case "complete" `Quick test_bidding_complete;
          Alcotest.test_case "bid_index" `Quick test_bid_index;
          Alcotest.test_case "opening 1NT" `Quick test_opening_1nt ] );
      ("scoring", [ Alcotest.test_case "values" `Quick test_scoring ]) ]
