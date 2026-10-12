open Types
open Cards

let legal_plays hand = function
  | None -> hand
  | Some lead_suit ->
    let in_suit = hand_suit_cards hand lead_suit in
    if in_suit = [] then hand else in_suit

let players_in_play_order leader =
  [ leader; next_player leader;
    next_player (next_player leader);
    next_player (next_player (next_player leader)) ]

let card_score c lead_suit trump_suit =
  match trump_suit with
  | Some ts when c.suit = ts -> 100 + rank_to_int c.rank
  | _ when c.suit = lead_suit -> 50 + rank_to_int c.rank
  | _ -> rank_to_int c.rank

let rec zip a b =
  match (a, b) with x :: xs, y :: ys -> (x, y) :: zip xs ys | _ -> []

let trick_winner trick leader trump_suit =
  match trick with
  | [] -> leader
  | lead_card :: _ ->
    let lead_suit = lead_card.suit in
    let score c = card_score c lead_suit trump_suit in
    let plays = zip trick (players_in_play_order leader) in
    let _, winner =
      List.fold_left
        (fun (bc, bp) (c, p) -> if score c > score bc then (c, p) else (bc, bp))
        (List.hd plays) (List.tl plays)
    in
    winner

let lowest_card = function
  | [] -> invalid_arg "lowest_card"
  | x :: xs ->
    List.fold_left
      (fun m c -> if rank_to_int c.rank < rank_to_int m.rank then c else m)
      x xs

let highest_card = function
  | [] -> invalid_arg "highest_card"
  | x :: xs ->
    List.fold_left
      (fun m c -> if rank_to_int c.rank > rank_to_int m.rank then c else m)
      x xs

let is_partner_winning trick leader trump_suit me =
  match trick with
  | [] -> false
  | _ -> side (trick_winner trick leader trump_suit) = side me

let can_win_trick in_suit trick _leader trump_suit =
  match (in_suit, trick) with
  | [], _ -> false
  | _, [] -> true
  | _, lead :: _ ->
    let lead_suit = lead.suit in
    let score c = card_score c lead_suit trump_suit in
    let winning = List.fold_left (fun m c -> max m (score c)) min_int trick in
    List.exists (fun c -> score c > winning) in_suit

let cheapest_winner in_suit trick _leader trump_suit =
  let lead_suit = (List.hd trick).suit in
  let score c = card_score c lead_suit trump_suit in
  let winning = List.fold_left (fun m c -> max m (score c)) min_int trick in
  let winners = List.filter (fun c -> score c > winning) in_suit in
  if winners = [] then lowest_card in_suit else lowest_card winners

let hand_longest_non_trump hand trump_suit =
  let suits =
    match trump_suit with
    | Some ts -> List.filter (fun s -> s <> ts) all_suits
    | None -> all_suits
  in
  let lengths = List.map (fun s -> (suit_length s hand, s)) suits in
  let cmp (l1, s1) (l2, s2) =
    match compare l2 l1 with 0 -> compare s2 s1 | c -> c
  in
  if lengths = [] then hand_longest_suit hand
  else snd (List.hd (List.sort cmp lengths))

let best_discard cards trump_suit =
  match cards with
  | [] -> invalid_arg "best_discard"
  | _ ->
    let longest = hand_longest_non_trump cards trump_suit in
    let in_longest = hand_suit_cards cards longest in
    if in_longest = [] then lowest_card cards else lowest_card in_longest

let lead_top_of_sequence hand trump_suit =
  let suits =
    match trump_suit with
    | Some ts -> List.filter (fun s -> s <> ts) all_suits
    | None -> all_suits
  in
  let check suit =
    let cards =
      List.sort
        (fun c1 c2 -> compare (rank_to_int c2.rank) (rank_to_int c1.rank))
        (hand_suit_cards hand suit)
    in
    match cards with
    | c1 :: c2 :: c3 :: _
      when rank_to_int c1.rank >= rank_to_int Jack
           && rank_to_int c1.rank = rank_to_int c2.rank + 1
           && rank_to_int c2.rank = rank_to_int c3.rank + 1 -> Some c1
    | _ -> None
  in
  List.find_map check suits

let lead_fourth_best hand trump_suit =
  let longest = hand_longest_non_trump hand trump_suit in
  let cards =
    List.sort
      (fun c1 c2 -> compare (rank_to_int c2.rank) (rank_to_int c1.rank))
      (hand_suit_cards hand longest)
  in
  if List.length cards >= 4 then Some (List.nth cards 3) else None

let lead_short_suit hand = function
  | None -> None
  | Some ts ->
    let side_suits = List.filter (fun s -> s <> ts) all_suits in
    let lengths =
      List.filter_map
        (fun s -> let l = suit_length s hand in if l > 0 then Some (l, s) else None)
        side_suits
      |> List.sort (fun (l1, _) (l2, _) -> compare l1 l2)
    in
    (match lengths with
     | (_, short_suit) :: _ ->
       let cards =
         List.sort
           (fun c1 c2 -> compare (rank_to_int c2.rank) (rank_to_int c1.rank))
           (hand_suit_cards hand short_suit)
       in
       Some (List.hd cards)
     | _ -> None)

let ( ||? ) o f = match o with Some _ -> o | None -> f ()

let ai_select_lead hand trump_suit me declarer =
  let defending = side me <> side declarer in
  if defending then
    (lead_top_of_sequence hand trump_suit |> fun o ->
     o ||? fun () -> lead_fourth_best hand trump_suit)
    |> (fun o -> o ||? fun () -> lead_short_suit hand trump_suit)
    |> (function
         | Some c -> c
         | None ->
           lowest_card (hand_suit_cards hand (hand_longest_non_trump hand trump_suit)))
  else
    match trump_suit with
    | Some ts
      when suit_length ts hand >= 3
           && List.exists (fun c -> c.rank >= Queen) (hand_suit_cards hand ts) ->
      highest_card (hand_suit_cards hand ts)
    | _ ->
      (lead_top_of_sequence hand trump_suit |> fun o ->
       o ||? fun () -> lead_fourth_best hand trump_suit)
      |> (function Some c -> c | None -> List.hd hand)

let ai_select_follow hand trick leader trump_suit me _declarer =
  let lead_suit = (List.hd trick).suit in
  let legal = legal_plays hand (Some lead_suit) in
  let cards_played = List.length trick in
  let partner_winning = is_partner_winning trick leader trump_suit me in
  match legal with
  | [ single ] -> single
  | _ when List.exists (fun c -> c.suit = lead_suit) legal ->
    let in_suit = List.filter (fun c -> c.suit = lead_suit) legal in
    if cards_played = 3 && partner_winning then lowest_card in_suit
    else if can_win_trick in_suit trick leader trump_suit then
      cheapest_winner in_suit trick leader trump_suit
    else lowest_card in_suit
  | _ ->
    let trumps, non_trumps =
      match trump_suit with
      | Some ts -> (List.filter (fun c -> c.suit = ts) legal,
                    List.filter (fun c -> c.suit <> ts) legal)
      | None -> ([], legal)
    in
    if (not partner_winning) && trumps <> [] then lowest_card trumps
    else if non_trumps <> [] then best_discard non_trumps trump_suit
    else lowest_card legal

let ai_select_card hand trick leader trump_suit me declarer =
  let lead_suit = match trick with c :: _ -> Some c.suit | [] -> None in
  let card =
    if trick = [] then ai_select_lead hand trump_suit me declarer
    else ai_select_follow hand trick leader trump_suit me declarer
  in
  let legal = legal_plays hand lead_suit in
  if List.mem card legal then card
  else match legal with fallback :: _ -> fallback | [] -> List.hd hand
