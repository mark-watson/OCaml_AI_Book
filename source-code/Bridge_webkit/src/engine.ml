open Types

module PMap = Map.Make (struct
  type t = player
  let compare = compare
end)

type vulnerability = Vul_none | Ns_only | Ew_only | Both

type game_state = {
  hands : card list PMap.t;
  original_hands : card list PMap.t;
  dealer : player;
  vulnerability : vulnerability;
  human_player : player;
  bid_history : (player * bid_type) list; (* newest first *)
  contract : bid_type option;
  declarer : player option;
  doubled : int;
  dummy : player option;
  current_trick : (player * card) list; (* newest first *)
  trick_lead : player;
  tricks_ns : int;
  tricks_ew : int;
  tricks_played : int;
  cards_played : card list;
  trump_suit : suit option;
  phase : phase;
}

let new_game dealer_val vul human_val seed =
  Random.init seed;
  let n, e, s, w = Cards.deal_hands (Cards.shuffle Cards.make_deck) in
  let hands =
    PMap.of_seq
      (List.to_seq [ (North, n); (East, e); (South, s); (West, w) ])
  in
  {
    hands; original_hands = hands; dealer = dealer_val; vulnerability = vul;
    human_player = human_val; bid_history = []; contract = None; declarer = None;
    doubled = 0; dummy = None; current_trick = []; trick_lead = dealer_val;
    tricks_ns = 0; tricks_ew = 0; tricks_played = 0; cards_played = [];
    trump_suit = None; phase = Bidding;
  }

let current_actor gs =
  match gs.phase with
  | Bidding -> (
    match gs.bid_history with
    | [] -> Some gs.dealer
    | (actor, _) :: _ -> Some (next_player actor))
  | Playing -> (
    match gs.current_trick with
    | [] -> Some gs.trick_lead
    | (actor, _) :: _ -> Some (next_player actor))
  | _ -> None

let apply_bid bid gs =
  match current_actor gs with
  | None -> gs
  | Some actor ->
    let history' = (actor, bid) :: gs.bid_history in
    if Bidding.bidding_complete history' then
      if Bidding.passed_out history' then
        { gs with bid_history = history'; phase = Done }
      else (
        match Bidding.extract_contract history' gs.dealer with
        | None -> { gs with bid_history = history'; phase = Done }
        | Some (contract', declarer', doubled') ->
          let ts =
            match contract' with
            | Suit_bid (_, Suit_strain s) -> Some s
            | _ -> None
          in
          (* If North declares and the human sits South, swap the N/S hands so
             the human plays the declaring hand; treat South as declarer. *)
          let hands', eff_declarer =
            if declarer' = North && gs.human_player = South then
              let north_cards = PMap.find North gs.hands in
              let south_cards = PMap.find South gs.hands in
              ( PMap.add North south_cards (PMap.add South north_cards gs.hands),
                South )
            else (gs.hands, declarer')
          in
          {
            gs with bid_history = history'; contract = Some contract';
            declarer = Some eff_declarer; doubled = doubled';
            dummy = Some (partner eff_declarer); trump_suit = ts;
            trick_lead = next_player eff_declarer; phase = Playing; hands = hands';
          })
    else { gs with bid_history = history' }

let apply_card_play card gs =
  match current_actor gs with
  | None -> gs
  | Some actor ->
    let hand' = List.filter (fun c -> c <> card) (PMap.find actor gs.hands) in
    let hands' = PMap.add actor hand' gs.hands in
    let current_trick' = (actor, card) :: gs.current_trick in
    let cards_played' = card :: gs.cards_played in
    if List.length current_trick' = 4 then begin
      let trick_in_play_order = List.map snd (List.rev current_trick') in
      let winner = Play.trick_winner trick_in_play_order gs.trick_lead gs.trump_suit in
      let ns_score = if winner = North || winner = South then 1 else 0 in
      let ew_score = if winner = East || winner = West then 1 else 0 in
      let tricks_played' = gs.tricks_played + 1 in
      {
        gs with hands = hands'; current_trick = []; trick_lead = winner;
        tricks_ns = gs.tricks_ns + ns_score; tricks_ew = gs.tricks_ew + ew_score;
        tricks_played = tricks_played'; cards_played = cards_played';
        phase = (if tricks_played' = 13 then Scoring else Playing);
      }
    end
    else
      { gs with hands = hands'; current_trick = current_trick'; cards_played = cards_played' }
