(* Auto-play one deal of contract bridge: the four AI players bid, play out the
   13 tricks, and the deal is scored. The Haskell version had an interactive TUI;
   this console driver exercises the same pure engine end to end. *)

open Bridge
open Bridge.Types

let show_hand_by_suit hand =
  List.map
    (fun s ->
      let cs =
        List.filter (fun c -> c.suit = s) hand
        |> List.sort (fun a b -> compare (rank_to_int b.rank) (rank_to_int a.rank))
      in
      Printf.sprintf "%s: %s" (show_suit s)
        (String.concat " " (List.map (fun c -> show_rank c.rank) cs)))
    [ Spades; Hearts; Diamonds; Clubs ]
  |> String.concat "   "

let () =
  Random.self_init ();
  let seed = Random.int 1_000_000_000 in
  let gs = ref (Engine.new_game North Engine.Vul_none South seed) in

  print_endline "=== Deal ===";
  List.iter
    (fun p ->
      Printf.printf "%-6s %s\n" (show_player p)
        (show_hand_by_suit (Engine.PMap.find p !gs.hands)))
    [ North; East; South; West ];

  print_endline "\n=== Bidding ===";
  while !gs.phase = Bidding do
    match Engine.current_actor !gs with
    | Some actor ->
      let hand = Engine.PMap.find actor !gs.hands in
      let bid = Bidding.ai_select_bid hand !gs.bid_history actor !gs.dealer in
      Printf.printf "%-6s %s\n" (show_player actor) (show_bid bid);
      gs := Engine.apply_bid bid !gs
    | None -> gs := { !gs with phase = Done }
  done;

  (match (!gs.contract, !gs.declarer) with
   | Some c, Some d ->
     Printf.printf "\nContract: %s by %s\n\n=== Play ===\n" (show_bid c) (show_player d)
   | _ -> print_endline "\nPassed out. No contract.");

  while !gs.phase = Playing do
    match Engine.current_actor !gs with
    | Some actor ->
      let hand = Engine.PMap.find actor !gs.hands in
      let trick = List.rev_map snd !gs.current_trick in
      let card =
        Play.ai_select_card hand trick !gs.trick_lead !gs.trump_suit actor
          (Option.get !gs.declarer)
      in
      Printf.printf "%-6s %s\n" (show_player actor) (show_card card);
      let before = !gs.tricks_played in
      gs := Engine.apply_card_play card !gs;
      if !gs.tricks_played > before then
        Printf.printf "  -> trick to %s   (N-S %d  E-W %d)\n"
          (show_player !gs.trick_lead) !gs.tricks_ns !gs.tricks_ew
    | None -> gs := { !gs with phase = Done }
  done;

  match (!gs.contract, !gs.declarer) with
  | Some (Suit_bid (level, strain)), Some declarer ->
    let tricks_won = if side declarer = 0 then !gs.tricks_ns else !gs.tricks_ew in
    let _, deal_score =
      Scoring.score_rubber_deal level strain tricks_won declarer !gs.doubled
        Scoring.new_rubber_state
    in
    Printf.printf "\n=== Result ===\nDeclarer took %d tricks; deal score %d\n"
      tricks_won deal_score
  | _ -> ()
