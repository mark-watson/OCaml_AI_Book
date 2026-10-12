(* Card model: ranks, suits, a deterministic ordered deck, and point values. *)

type suit = Hearts | Diamonds | Clubs | Spades

type rank =
  | Two | Three | Four | Five | Six | Seven | Eight
  | Nine | Ten | Jack | Queen | King | Ace

type card = { rank : rank; suit : suit }

let all_suits = [ Hearts; Diamonds; Clubs; Spades ]

let all_ranks =
  [ Two; Three; Four; Five; Six; Seven; Eight; Nine; Ten; Jack; Queen; King;
    Ace ]

let card_value c =
  match c.rank with
  | Two -> 2 | Three -> 3 | Four -> 4 | Five -> 5 | Six -> 6 | Seven -> 7
  | Eight -> 8 | Nine -> 9 | Ten -> 10 | Jack -> 10 | Queen -> 10 | King -> 10
  | Ace -> 11

(* 52 cards, ranks outer and suits inner, matching the Haskell deck order. *)
let ordered_card_deck =
  List.concat_map
    (fun r -> List.map (fun s -> { rank = r; suit = s }) all_suits)
    all_ranks

let rank_char = function
  | Two -> "2" | Three -> "3" | Four -> "4" | Five -> "5" | Six -> "6"
  | Seven -> "7" | Eight -> "8" | Nine -> "9" | Ten -> "10" | Jack -> "J"
  | Queen -> "Q" | King -> "K" | Ace -> "A"

let suit_char = function
  | Hearts -> "H" | Diamonds -> "D" | Clubs -> "C" | Spades -> "S"

let show_card c = rank_char c.rank ^ suit_char c.suit
let show_hand cs = String.concat " " (List.map show_card cs)
let hand_value cs = List.fold_left (fun acc c -> acc + card_value c) 0 cs
