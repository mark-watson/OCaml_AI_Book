(* Game state and rules for Blackjack, ported from the Haskell Table module.
   Haskell used lenses to update nested fields; OCaml uses record-update and a
   small list_set helper.

   Player index convention: 0 = human, 1 = dealer, 2..n = AI players. *)

type table = {
  num_players : int;
  chip_stacks : int list;      (* indexed by player index *)
  dealt_cards : Card.card list list;
  current_player_bet : int;
  user_passes : bool;
  card_deck : Card.card list;
}

let list_set i v lst = List.mapi (fun j x -> if j = i then v else x) lst

let rec drop n lst =
  if n <= 0 then lst else match lst with [] -> [] | _ :: tl -> drop (n - 1) tl

let create_new_table n =
  {
    num_players = n;
    chip_stacks = List.init n (fun _ -> 500);
    dealt_cards = List.init (n + 1) (fun _ -> []);
    current_player_bet = 20;
    user_passes = false;
    card_deck = [];
  }

let reset_table card_deck t number_of_players =
  {
    t with
    num_players = number_of_players;
    dealt_cards = List.init (number_of_players + 1) (fun _ -> []);
    user_passes = false;
    card_deck;
  }

let set_card_deck deck t = { t with card_deck = deck }
let set_player_bet bet t = { t with current_player_bet = bet }
let hand_over t = t.user_passes

let score t player_index =
  Card.hand_value (List.nth t.dealt_cards player_index)

let deal_card_to_user' t player_index =
  match t.card_deck with
  | [] -> t
  | next :: rest ->
    let player_cards = next :: List.nth t.dealt_cards player_index in
    {
      t with
      card_deck = rest;
      dealt_cards = list_set player_index player_cards t.dealt_cards;
    }

(* User always draws; other players draw only while under 17. *)
let deal_card_to_user t player_index =
  if player_index = 0 then deal_card_to_user' t player_index
  else if score t player_index < 17 then deal_card_to_user' t player_index
  else t

let deal_cards t player_indices =
  List.fold_left deal_card_to_user t player_indices

let initial_deal card_deck t number_of_players =
  let indices = List.init (number_of_players + 1) Fun.id in
  deal_cards (deal_cards (reset_table card_deck t number_of_players) indices) indices

let clip_score t player_index =
  let s = score t player_index in
  if s < 22 then s else 0

(* Resolve bets against the dealer; busts count as 0. *)
let score_hands t =
  let chips = t.chip_stacks in
  let player_score = clip_score t 0 in
  let dealer_score = clip_score t 1 in
  let head = List.hd chips in
  let new_player =
    if player_score > dealer_score then head + t.current_player_bet
    else if player_score < dealer_score then head - t.current_player_bet
    else head
  in
  let new_others =
    List.mapi
      (fun k y ->
        let x = clip_score t (2 + k) in
        if x > dealer_score then y + 20
        else if x < dealer_score then y - 20
        else y)
      (drop 2 chips)
  in
  let dealer_chip = List.nth chips 1 in
  { t with chip_stacks = (new_player :: dealer_chip :: new_others) }

let set_player_passes t =
  let indices = List.init t.num_players (fun i -> i + 1) in
  let t = { t with user_passes = true } in
  let t = deal_cards t indices in
  let t = deal_cards t indices in
  deal_cards t indices

let change_chip_stack player_index new_value t =
  { t with chip_stacks = list_set player_index new_value t.chip_stacks }

let show_table t =
  let vals hand = "[" ^ String.concat "," (List.map (fun c -> string_of_int (Card.card_value c)) hand) ^ "]" in
  Printf.sprintf
    "\nCurrent table data:\n  Chipstacks:\n    Player: %d\n    Other players: \
     %s\n  User cards: %s\n  Dealer cards: %s\n  Dealt card values: %s\n  \
     Current player bet: %d\n  Player pass: %b\n"
    (List.hd t.chip_stacks)
    (String.concat "," (List.map string_of_int (List.tl t.chip_stacks)))
    (Card.show_hand (List.nth t.dealt_cards 0))
    (Card.show_hand (List.nth t.dealt_cards 1))
    (String.concat " " (List.map vals t.dealt_cards))
    t.current_player_bet t.user_passes
