(* Marshal the game state to the exact JSON shape the frontend index.html reads.
   Ported from the Haskell makePayload (the field names match the Aeson-derived
   keys, e.g. hlNorth, bePlayer, pcCard, nsBelow). *)

open Types

let show_phase = function
  | Dealing -> "Dealing" | Bidding -> "Bidding" | Playing -> "Playing"
  | Scoring -> "Scoring" | Done -> "Done"

let show_vul = function
  | Engine.Vul_none -> "None" | Ns_only -> "NsOnly" | Ew_only -> "EwOnly"
  | Both -> "Both"

let show_suit_full = function
  | Clubs -> "Clubs" | Diamonds -> "Diamonds" | Hearts -> "Hearts"
  | Spades -> "Spades"

let opt_string f = function Some x -> `String (f x) | None -> `Null
let card_codes cards = `List (List.map (fun c -> `String (show_card c)) cards)

let hand_list get (m : card list Engine.PMap.t) =
  `Assoc
    [ ("hlNorth", card_codes (get North m)); ("hlEast", card_codes (get East m));
      ("hlSouth", card_codes (get South m)); ("hlWest", card_codes (get West m)) ]

let pmap_find p m = Engine.PMap.find p m

let played_card p c =
  `Assoc [ ("pcPlayer", `String (show_player p)); ("pcCard", `String (show_card c)) ]

let last_of = function [] -> None | l -> Some (List.nth l (List.length l - 1))

let rubber_state_json (rs : Scoring.rubber_state) =
  `Assoc
    [ ("nsBelow", `Int rs.ns_below); ("ewBelow", `Int rs.ew_below);
      ("nsAbove", `Int rs.ns_above); ("ewAbove", `Int rs.ew_above);
      ("nsGames", `Int rs.ns_games); ("ewGames", `Int rs.ew_games);
      ("nsVulnerable", `Bool rs.ns_vulnerable);
      ("ewVulnerable", `Bool rs.ew_vulnerable);
      ("currentDealer", `String (show_player rs.current_dealer));
      ("dealsPlayed", `Int rs.deals_played) ]

let make_payload (gs : Engine.game_state) (rs : Scoring.rubber_state) deal_num
    last_trick =
  let actor = Engine.current_actor gs in
  let lead_suit =
    match last_of gs.current_trick with
    | Some (_, c) -> Some (card_suit c)
    | None -> None
  in
  let is_human = actor = Some South in
  let is_dummy = actor = gs.dummy in
  let declarer_side = Option.map side gs.declarer in
  let human_plays_dummy = is_dummy && declarer_side = Some 0 in
  let human_plays_this = is_human || human_plays_dummy in
  let legal_list =
    if gs.phase = Playing && human_plays_this then
      match actor with
      | Some act -> Play.legal_plays (pmap_find act gs.hands) lead_suit
      | None -> []
    else []
  in
  let is_dummy_vis =
    gs.phase = Playing && (gs.cards_played <> [] || human_plays_this)
  in
  let played_card_list =
    `List (List.rev_map (fun (p, c) -> played_card p c) gs.current_trick)
  in
  let bid_entry_list =
    `List
      (List.rev_map
         (fun (p, b) ->
           `Assoc [ ("bePlayer", `String (show_player p)); ("beBid", `String (show_bid b)) ])
         gs.bid_history)
  in
  `Assoc
    [ ("phase", `String (show_phase gs.phase));
      ("dealer", `String (show_player gs.dealer));
      ("vulnerability", `String (show_vul gs.vulnerability));
      ("humanPlayer", `String (show_player gs.human_player));
      ("activeActor", opt_string show_player actor);
      ("hands", hand_list pmap_find gs.hands);
      ("originalHands", hand_list pmap_find gs.original_hands);
      ("bidHistory", bid_entry_list);
      ("contract", opt_string show_bid gs.contract);
      ("declarer", opt_string show_player gs.declarer);
      ("doubled", `Int gs.doubled);
      ("dummy", opt_string show_player gs.dummy);
      ("dummyVisible", `Bool is_dummy_vis);
      ("currentTrick", played_card_list);
      ("lastCompletedTrick", last_trick);
      ("trickLead", `String (show_player gs.trick_lead));
      ("tricksNs", `Int gs.tricks_ns);
      ("tricksEw", `Int gs.tricks_ew);
      ("tricksPlayed", `Int gs.tricks_played);
      ("trumpSuit", opt_string show_suit_full gs.trump_suit);
      ("rubberState", rubber_state_json rs);
      ("legalCards", card_codes legal_list);
      ("dealNum", `Int deal_num) ]
