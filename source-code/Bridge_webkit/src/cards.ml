open Types

let make_deck =
  List.concat_map
    (fun s -> List.map (fun r -> { suit = s; rank = r }) all_ranks)
    all_suits

let shuffle lst =
  let a = Array.of_list lst in
  for i = Array.length a - 1 downto 1 do
    let j = Random.int (i + 1) in
    let t = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- t
  done;
  Array.to_list a

let sort_hand hand = List.sort compare_bridge hand

(* Round-robin deal N,E,S,W, then sort each hand. *)
let deal_hands deck =
  let n = ref [] and e = ref [] and s = ref [] and w = ref [] in
  List.iteri
    (fun i c ->
      match i mod 4 with
      | 0 -> n := c :: !n
      | 1 -> e := c :: !e
      | 2 -> s := c :: !s
      | _ -> w := c :: !w)
    deck;
  (sort_hand !n, sort_hand !e, sort_hand !s, sort_hand !w)

let card_hcp c =
  match c.rank with Ace -> 4 | King -> 3 | Queen -> 2 | Jack -> 1 | _ -> 0

let hand_hcp hand = List.fold_left (fun a c -> a + card_hcp c) 0 hand
let suit_length suit hand = List.length (List.filter (fun c -> c.suit = suit) hand)
let hand_suit_cards hand suit = List.filter (fun c -> c.suit = suit) hand

let hand_shape hand =
  [ suit_length Spades hand; suit_length Hearts hand; suit_length Diamonds hand;
    suit_length Clubs hand ]

let hand_shape_sorted hand = List.rev (List.sort compare (hand_shape hand))

let hand_length_points hand =
  List.fold_left
    (fun a s -> let len = suit_length s hand in if len > 4 then a + (len - 4) else a)
    0 all_suits

let hand_shortness_points hand =
  List.fold_left
    (fun a s ->
      let len = suit_length s hand in
      a + (match len with 0 -> 3 | 1 -> 2 | 2 -> 1 | _ -> 0))
    0 all_suits

let hand_total_points hand trump_fit_found =
  hand_hcp hand
  + (if trump_fit_found then hand_shortness_points hand else hand_length_points hand)

let is_balanced hand =
  let sh = hand_shape_sorted hand in
  sh = [ 4; 3; 3; 3 ] || sh = [ 4; 4; 3; 2 ] || sh = [ 5; 3; 3; 2 ]

let is_semi_balanced hand =
  is_balanced hand
  ||
  let sh = hand_shape_sorted hand in
  sh = [ 5; 4; 2; 2 ] || sh = [ 6; 3; 2; 2 ]

let hand_has_major hand min_len =
  suit_length Hearts hand >= min_len || suit_length Spades hand >= min_len

let hand_longest_suit hand =
  let lengths = List.map (fun s -> (suit_length s hand, s)) all_suits in
  let cmp (l1, s1) (l2, s2) =
    match compare l2 l1 with 0 -> compare s2 s1 | c -> c
  in
  snd (List.hd (List.sort cmp lengths))

let hand_suit_hcp hand suit =
  List.fold_left (fun a c -> if c.suit = suit then a + card_hcp c else a) 0 hand

let hand_has_stopper hand suit =
  let cards = hand_suit_cards hand suit in
  let len = List.length cards in
  let ranks = List.map card_rank cards in
  len > 0
  && (List.mem Ace ranks
     || (len >= 2 && List.mem King ranks)
     || (len >= 3 && List.mem Queen ranks)
     || (len >= 4 && List.mem Jack ranks))

let hand_suit_honor_count hand suit =
  List.length
    (List.filter (fun c -> c.suit = suit && rank_to_int c.rank >= rank_to_int R10) hand)
