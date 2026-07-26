open Blackjack

let card rank suit = { Card.rank; suit }

let test_values () =
  Alcotest.(check int) "ace" 11 (Card.card_value (card Card.Ace Card.Spades));
  Alcotest.(check int) "king" 10 (Card.card_value (card Card.King Card.Hearts));
  Alcotest.(check int) "two" 2 (Card.card_value (card Card.Two Card.Clubs))

let test_deck () =
  Alcotest.(check int) "52 cards" 52 (List.length Card.ordered_card_deck);
  Alcotest.(check int) "all distinct" 52
    (List.length (List.sort_uniq compare Card.ordered_card_deck))

let sample_table () =
  {
    Table.num_players = 2;
    chip_stacks = [ 500; 500 ];
    dealt_cards =
      [ [ card Card.King Card.Hearts; card Card.Ten Card.Spades ];
        [ card Card.Nine Card.Clubs; card Card.Eight Card.Diamonds ];
        [ card Card.King Card.Clubs; card Card.King Card.Diamonds;
          card Card.Five Card.Hearts ] ];
    current_player_bet = 20;
    user_passes = false;
    card_deck = [];
  }

let test_score () =
  let t = sample_table () in
  Alcotest.(check int) "user 20" 20 (Table.score t 0);
  Alcotest.(check int) "dealer 17" 17 (Table.score t 1);
  Alcotest.(check int) "ai bust clipped to 0" 0 (Table.clip_score t 2)

let test_score_hands () =
  let t = Table.score_hands (sample_table ()) in
  Alcotest.(check (list int)) "chips after a win" [ 520; 500 ] t.Table.chip_stacks

let test_initial_deal () =
  let t = Table.initial_deal Card.ordered_card_deck (Table.create_new_table 2) 2 in
  Alcotest.(check int) "three hands" 3 (List.length t.Table.dealt_cards);
  List.iter
    (fun h -> Alcotest.(check int) "two cards each" 2 (List.length h))
    t.Table.dealt_cards

let () =
  Alcotest.run "Blackjack"
    [ ( "card",
        [ Alcotest.test_case "values" `Quick test_values;
          Alcotest.test_case "deck" `Quick test_deck ] );
      ( "table",
        [ Alcotest.test_case "score" `Quick test_score;
          Alcotest.test_case "score_hands" `Quick test_score_hands;
          Alcotest.test_case "initial_deal" `Quick test_initial_deal ] ) ]
