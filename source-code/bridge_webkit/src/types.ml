(* Core bridge types. The constructor order is chosen so OCaml's polymorphic
   compare matches the Haskell derived/custom Ord instances: suits low to high,
   ranks 2 to Ace, players N,E,S,W, and SuitStrain below NoTrump. *)

type suit = Clubs | Diamonds | Hearts | Spades

type rank =
  | R2 | R3 | R4 | R5 | R6 | R7 | R8 | R9 | R10 | Jack | Queen | King | Ace

type card = { suit : suit; rank : rank }

let card_suit c = c.suit
let card_rank c = c.rank

let rank_to_int = function
  | R2 -> 0 | R3 -> 1 | R4 -> 2 | R5 -> 3 | R6 -> 4 | R7 -> 5 | R8 -> 6
  | R9 -> 7 | R10 -> 8 | Jack -> 9 | Queen -> 10 | King -> 11 | Ace -> 12

let all_suits = [ Clubs; Diamonds; Hearts; Spades ]

let all_ranks =
  [ R2; R3; R4; R5; R6; R7; R8; R9; R10; Jack; Queen; King; Ace ]

(* Bridge sort: suit then rank, both descending (used when showing a hand). *)
let compare_bridge a b =
  match compare b.suit a.suit with 0 -> compare b.rank a.rank | c -> c

type player = North | East | South | West

let partner = function
  | North -> South | South -> North | East -> West | West -> East

let next_player = function
  | North -> East | East -> South | South -> West | West -> North

let side = function North | South -> 0 | East | West -> 1

type strain = Suit_strain of suit | No_trump

type bid_type =
  | Suit_bid of int * strain
  | Pass
  | Double_bid
  | Redouble_bid

type phase = Dealing | Bidding | Playing | Scoring | Done

let show_suit = function
  | Clubs -> "C" | Diamonds -> "D" | Hearts -> "H" | Spades -> "S"

let show_rank = function
  | Ace -> "A" | King -> "K" | Queen -> "Q" | Jack -> "J" | R10 -> "10"
  | r -> string_of_int (rank_to_int r + 2)

let show_card c = show_rank c.rank ^ show_suit c.suit

let show_player = function
  | North -> "North" | East -> "East" | South -> "South" | West -> "West"

let show_strain = function Suit_strain s -> show_suit s | No_trump -> "NT"

let show_bid = function
  | Suit_bid (level, strain) -> string_of_int level ^ show_strain strain
  | Pass -> "Pass"
  | Double_bid -> "Dbl"
  | Redouble_bid -> "Rdbl"
