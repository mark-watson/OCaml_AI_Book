(* Parse bid text typed by the human player, ported from the Haskell
   BridgeWebKit.Parsing module. *)

open Types

let trim s =
  let n = String.length s in
  let i = ref 0 and j = ref (n - 1) in
  while !i < n && s.[!i] = ' ' do incr i done;
  while !j >= !i && s.[!j] = ' ' do decr j done;
  if !j < !i then "" else String.sub s !i (!j - !i + 1)

let parse_strain = function
  | "C" | "CLUBS" -> Some (Suit_strain Clubs)
  | "D" | "DIAMONDS" -> Some (Suit_strain Diamonds)
  | "H" | "HEARTS" -> Some (Suit_strain Hearts)
  | "S" | "SPADES" -> Some (Suit_strain Spades)
  | "N" | "NT" | "NOTRUMP" | "NO TRUMP" -> Some No_trump
  | _ -> None

let parse_bid_input raw =
  let s = String.uppercase_ascii (trim raw) in
  match s with
  | "PASS" | "P" -> Some Pass
  | "DOUBLE" | "DBL" | "X" -> Some Double_bid
  | "REDOUBLE" | "RDBL" | "XX" -> Some Redouble_bid
  | _ ->
    if String.length s >= 1 && s.[0] >= '0' && s.[0] <= '9' then
      let level = Char.code s.[0] - Char.code '0' in
      if level >= 1 && level <= 7 then
        match parse_strain (String.sub s 1 (String.length s - 1)) with
        | Some strain -> Some (Suit_bid (level, strain))
        | None -> None
      else None
    else None
