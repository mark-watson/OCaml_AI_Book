open Types
open Cards

let is_suit_bid = function Suit_bid _ -> true | _ -> false

let last_suit_bid history =
  match List.find_opt (fun (_, b) -> is_suit_bid b) history with
  | Some (_, b) -> Some b
  | None -> None

(* 1C = 0, 1D = 1, ..., 7NT = 34 *)
let bid_index = function
  | Suit_bid (level, strain) ->
    let si =
      match strain with
      | Suit_strain Clubs -> 0 | Suit_strain Diamonds -> 1
      | Suit_strain Hearts -> 2 | Suit_strain Spades -> 3 | No_trump -> 4
    in
    Some (((level - 1) * 5) + si)
  | _ -> None

let bid_higher_than b1 b2 =
  match (bid_index b1, bid_index b2) with
  | Some i1, Some i2 -> i1 > i2
  | _ -> false

let bidding_complete history =
  let bids = List.map snd history in
  let has_suit_bid = List.exists is_suit_bid bids in
  match bids with
  | _ when List.length bids = 4 && List.for_all (fun b -> b = Pass) bids -> true
  | Pass :: Pass :: Pass :: _ when has_suit_bid -> true
  | _ -> false

let passed_out history =
  List.length history = 4 && List.for_all (fun (_, b) -> b = Pass) history

let extract_contract history _dealer =
  let rec find_last_suit = function
    | (p, Suit_bid (l, s)) :: _ -> Some (Suit_bid (l, s), p)
    | _ :: xs -> find_last_suit xs
    | [] -> None
  in
  match find_last_suit history with
  | Some ((Suit_bid (_, strain) as contract), final_bidder) ->
    let decl_side = side final_bidder in
    let chrono = List.rev history in
    let rec first_bidder = function
      | (p, Suit_bid (_, s)) :: xs ->
        if s = strain && side p = decl_side then p else first_bidder xs
      | _ :: xs -> first_bidder xs
      | [] -> final_bidder
    in
    let declarer = first_bidder chrono in
    let rec check_double lst d =
      match lst with
      | (_, Suit_bid _) :: _ -> d
      | (_, Double_bid) :: xs when d = 0 -> check_double xs 1
      | (_, Redouble_bid) :: xs when d = 1 -> check_double xs 2
      | _ :: xs -> check_double xs d
      | [] -> d
    in
    Some (contract, declarer, check_double history 0)
  | _ -> None

let first_suit_bid_of history who =
  let chrono = List.rev history in
  match
    List.filter_map
      (fun (bidder, bid) -> if bidder = who && is_suit_bid bid then Some bid else None)
      chrono
  with
  | first :: _ -> Some first
  | [] -> None

let find_partner_opening history me = first_suit_bid_of history (partner me)
let find_my_opening history me = first_suit_bid_of history me

let stayman_response_p a b =
  match (a, b) with
  | Suit_bid (2, Suit_strain Clubs), Suit_bid (1, No_trump) -> true
  | Suit_bid (3, Suit_strain Clubs), Suit_bid (2, No_trump) -> true
  | _ -> false

let blackwood_response_p = function Suit_bid (4, No_trump) -> true | _ -> false
let blackwood_king_ask_p = function Suit_bid (5, No_trump) -> true | _ -> false

let gerber_response_p a b =
  match (a, b) with
  | Suit_bid (4, Suit_strain Clubs), Suit_bid (_, No_trump) -> true
  | _ -> false

let gerber_king_ask_p = function Suit_bid (5, Suit_strain Clubs) -> true | _ -> false

let ai_opening_bid hand =
  let hcp = hand_hcp hand in
  let balanced = is_balanced hand in
  let opening_suit =
    if suit_length Spades hand >= 5 then Suit_strain Spades
    else if suit_length Hearts hand >= 5 then Suit_strain Hearts
    else if suit_length Diamonds hand > suit_length Clubs hand then Suit_strain Diamonds
    else Suit_strain Clubs
  in
  let seven_card_suits =
    List.filter_map
      (fun s ->
        if suit_length s hand >= 7 && hand_suit_honor_count hand s >= 2 then
          Some (Suit_strain s)
        else None)
      all_suits
  in
  let weak_two_suits =
    List.filter_map
      (fun s -> if suit_length s hand >= 6 then Some (Suit_strain s) else None)
      [ Diamonds; Hearts; Spades ]
  in
  if hcp >= 22 then Some (Suit_bid (2, Suit_strain Clubs))
  else if balanced && hcp >= 20 && hcp <= 21 then Some (Suit_bid (2, No_trump))
  else if balanced && hcp >= 15 && hcp <= 17 then Some (Suit_bid (1, No_trump))
  else if hcp >= 13 && hcp <= 21 then Some (Suit_bid (1, opening_suit))
  else if hcp < 13 && seven_card_suits <> [] then
    Some (Suit_bid (3, List.hd seven_card_suits))
  else if hcp < 13 && hcp >= 5 && weak_two_suits <> [] then
    Some (Suit_bid (2, List.hd weak_two_suits))
  else None

let respond_to_1nt hand hcp =
  let s = suit_length Spades hand and h = suit_length Hearts hand in
  let d = suit_length Diamonds hand in
  if hcp <= 7 then
    if s >= 5 then Some (Suit_bid (2, Suit_strain Spades))
    else if h >= 5 then Some (Suit_bid (2, Suit_strain Hearts))
    else if d >= 5 then Some (Suit_bid (2, Suit_strain Diamonds))
    else None
  else if hcp >= 8 && (h >= 4 || s >= 4) then Some (Suit_bid (2, Suit_strain Clubs))
  else if hcp <= 9 then Some (Suit_bid (2, No_trump))
  else if hcp <= 15 && s >= 6 then Some (Suit_bid (4, Suit_strain Spades))
  else if hcp <= 15 && h >= 6 then Some (Suit_bid (4, Suit_strain Hearts))
  else if hcp <= 15 && s >= 5 then Some (Suit_bid (3, Suit_strain Spades))
  else if hcp <= 15 && h >= 5 then Some (Suit_bid (3, Suit_strain Hearts))
  else if hcp <= 15 then Some (Suit_bid (3, No_trump))
  else Some (Suit_bid (4, No_trump))

let respond_to_2nt hand hcp =
  let h = suit_length Hearts hand and s = suit_length Spades hand in
  if hcp <= 4 && List.for_all (fun su -> suit_length su hand < 5) all_suits then None
  else if hcp >= 4 && (h >= 4 || s >= 4) then Some (Suit_bid (3, Suit_strain Clubs))
  else if hcp >= 5 then Some (Suit_bid (3, No_trump))
  else None

let respond_to_major hand hcp p_suit =
  if hcp <= 5 then None
  else if hcp <= 10 then
    if suit_length p_suit hand >= 3 then Some (Suit_bid (2, Suit_strain p_suit))
    else if p_suit = Hearts && suit_length Spades hand >= 4 then
      Some (Suit_bid (1, Suit_strain Spades))
    else Some (Suit_bid (1, No_trump))
  else if hcp <= 12 then
    if suit_length p_suit hand >= 3 then Some (Suit_bid (3, Suit_strain p_suit))
    else
      let longest = hand_longest_suit hand in
      if longest > p_suit then Some (Suit_bid (2, Suit_strain longest))
      else Some (Suit_bid (2, No_trump))
  else if suit_length p_suit hand >= 3 then Some (Suit_bid (4, Suit_strain p_suit))
  else Some (Suit_bid (3, No_trump))

let respond_to_minor hand hcp p_suit =
  let h_len = suit_length Hearts hand and s_len = suit_length Spades hand in
  if hcp < 6 then None
  else if h_len >= 4 || s_len >= 4 then
    Some
      (if h_len >= 5 && s_len >= 5 then Suit_bid (1, Suit_strain Spades)
       else if h_len >= 4 && s_len >= 4 then Suit_bid (1, Suit_strain Hearts)
       else if h_len >= 4 then Suit_bid (1, Suit_strain Hearts)
       else Suit_bid (1, Suit_strain Spades))
  else if hcp <= 10 then Some (Suit_bid (1, No_trump))
  else if hcp <= 12 then
    if suit_length p_suit hand >= 4 then Some (Suit_bid (3, Suit_strain p_suit))
    else Some (Suit_bid (2, No_trump))
  else if hcp <= 15 then
    if suit_length p_suit hand >= 4 then Some (Suit_bid (5, Suit_strain p_suit))
    else Some (Suit_bid (3, No_trump))
  else Some (Suit_bid (4, No_trump))

let respond_to_2c hand hcp =
  if hcp < 8 then Some (Suit_bid (2, Suit_strain Diamonds))
  else if (not (is_balanced hand)) && suit_length Spades hand >= 5 then
    Some (Suit_bid (2, Suit_strain Spades))
  else if (not (is_balanced hand)) && suit_length Hearts hand >= 5 then
    Some (Suit_bid (2, Suit_strain Hearts))
  else if (not (is_balanced hand)) && suit_length Diamonds hand >= 5 then
    Some (Suit_bid (3, Suit_strain Diamonds))
  else if (not (is_balanced hand)) && suit_length Clubs hand >= 5 then
    Some (Suit_bid (3, Suit_strain Clubs))
  else Some (Suit_bid (2, No_trump))

let respond_to_preempt hand hcp p_level p_suit =
  if p_level = 2 then
    if suit_length p_suit hand >= 3 && hcp >= 14 then Some (Suit_bid (4, Suit_strain p_suit))
    else if suit_length p_suit hand >= 3 && hcp >= 10 then Some (Suit_bid (3, Suit_strain p_suit))
    else None
  else if suit_length p_suit hand >= 3 && hcp >= 14 then
    Some (Suit_bid ((if p_suit >= Hearts then 4 else 5), Suit_strain p_suit))
  else None

let ai_responding_bid hand partner_bid =
  match partner_bid with
  | Suit_bid (p_level, No_trump) ->
    let hcp = hand_hcp hand in
    if p_level = 1 then respond_to_1nt hand hcp else respond_to_2nt hand hcp
  | Suit_bid (p_level, Suit_strain p_suit) ->
    let hcp = hand_hcp hand in
    if p_level = 1 then
      if p_suit >= Hearts then respond_to_major hand hcp p_suit
      else respond_to_minor hand hcp p_suit
    else if p_suit = Clubs then respond_to_2c hand hcp
    else respond_to_preempt hand hcp p_level p_suit
  | _ -> None

let int_to_strain = function
  | 0 -> Suit_strain Clubs | 1 -> Suit_strain Diamonds
  | 2 -> Suit_strain Hearts | 3 -> Suit_strain Spades | _ -> No_trump

let count_rank hand r = List.length (List.filter (fun c -> c.rank = r) hand)
let bid_level = function Suit_bid (l, _) -> l | _ -> 1

let ai_opener_rebid hand my_opening partner_response =
  match (my_opening, partner_response) with
  | Suit_bid (_, my_strain), Suit_bid (p_level, p_strain) ->
    let hcp = hand_hcp hand in
    let h = suit_length Hearts hand and s = suit_length Spades hand in
    if stayman_response_p partner_response my_opening then
      let lvl = if bid_level my_opening = 1 then 2 else 3 in
      Some
        (if h >= 4 && s >= 4 then Suit_bid (lvl, Suit_strain Hearts)
         else if h >= 4 then Suit_bid (lvl, Suit_strain Hearts)
         else if s >= 4 then Suit_bid (lvl, Suit_strain Spades)
         else Suit_bid (lvl, Suit_strain Diamonds))
    else if blackwood_response_p partner_response then
      Some (Suit_bid (5, int_to_strain (count_rank hand Ace mod 5)))
    else if blackwood_king_ask_p partner_response then
      Some (Suit_bid (6, int_to_strain (count_rank hand King mod 5)))
    else if gerber_response_p partner_response my_opening then
      Some
        (match count_rank hand Ace with
         | 0 -> Suit_bid (4, Suit_strain Diamonds)
         | 1 -> Suit_bid (4, Suit_strain Hearts)
         | 2 -> Suit_bid (4, Suit_strain Spades)
         | 3 -> Suit_bid (4, No_trump)
         | _ -> Suit_bid (5, Suit_strain Clubs))
    else if gerber_king_ask_p partner_response then
      Some
        (match count_rank hand King with
         | 0 -> Suit_bid (5, Suit_strain Diamonds)
         | 1 -> Suit_bid (5, Suit_strain Hearts)
         | 2 -> Suit_bid (5, Suit_strain Spades)
         | 3 -> Suit_bid (5, No_trump)
         | _ -> Suit_bid (6, Suit_strain Clubs))
    else if p_strain = No_trump then
      (match my_strain with
       | Suit_strain sm when suit_length sm hand >= 6 ->
         Some (Suit_bid (p_level + 1, my_strain))
       | _ when hcp <= 15 -> None
       | _ when hcp <= 17 -> Some (Suit_bid (p_level + 1, No_trump))
       | _ -> Some (Suit_bid (p_level + 2, No_trump)))
    else
      (match (my_strain, p_strain) with
       | Suit_strain sm, Suit_strain ps when sm = ps ->
         (* partner raised my suit *)
         if hcp <= 15 then None
         else if hcp >= 19 && sm >= Hearts then Some (Suit_bid (4, No_trump))
         else if sm >= Hearts && hcp <= 18 then Some (Suit_bid (4, my_strain))
         else Some (Suit_bid ((if sm >= Hearts then 4 else 5), my_strain))
       | _, Suit_strain ps ->
         (* partner bid a new suit *)
         if suit_length ps hand >= 4 then Some (Suit_bid (p_level + 1, p_strain))
         else
           (match my_strain with
            | Suit_strain sm when suit_length sm hand >= 6 -> Some (Suit_bid (2, my_strain))
            | _ when hcp <= 15 && is_balanced hand ->
              Some (Suit_bid ((if p_level >= 2 then p_level else 1), No_trump))
            | Suit_strain sm when suit_length sm hand >= 5 -> Some (Suit_bid (2, my_strain))
            | _ -> Some (Suit_bid (1, No_trump)))
       | _ -> None)
  | _ -> None

let ensure_legal_bid raw current =
  match raw with
  | None -> None
  | Some bid -> (
    match current with
    | None -> Some bid
    | Some highest ->
      if not (is_suit_bid bid) then Some bid
      else if bid_higher_than bid highest then Some bid
      else None)

let ai_select_bid hand history me _dealer =
  let current_highest = last_suit_bid history in
  let partner_bid = find_partner_opening history me in
  let my_bid = find_my_opening history me in
  let raw_bid =
    match (my_bid, partner_bid) with
    | Some mb, Some pb -> ai_opener_rebid hand mb pb
    | None, Some pb -> ai_responding_bid hand pb
    | _ -> (
      match current_highest with
      | None -> ai_opening_bid hand
      | Some _ ->
        let hcp = hand_hcp hand in
        if hcp >= 13 && hand_has_major hand 5 then
          if suit_length Spades hand >= 5 then Some (Suit_bid (1, Suit_strain Spades))
          else Some (Suit_bid (1, Suit_strain Hearts))
        else if hcp >= 15 && hcp <= 18 && is_balanced hand then
          Some (Suit_bid (1, No_trump))
        else None)
  in
  match ensure_legal_bid raw_bid current_highest with Some b -> b | None -> Pass
