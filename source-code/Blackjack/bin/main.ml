(* Console front end for Blackjack. The Haskell version used a Brick terminal
   UI; the OCaml standard stack has no Brick equivalent, so this is a plain
   text loop with the same controls:

     h = hit   s = stay   1/2/3 = bet 10/20/30   n = new hand   q = quit *)

module Card = Blackjack.Card
module Table = Blackjack.Table
module Shuffle = Blackjack.Shuffle

type phase = Playing | Hand_over of string

let fresh_deck () = Shuffle.shuffle Card.ordered_card_deck

let score_for_player (t : Table.table) i =
  if i < List.length t.dealt_cards then Card.hand_value (List.nth t.dealt_cards i)
  else 0

let build_result_msg (t : Table.table) =
  let ps = score_for_player t 0 in
  let ds = score_for_player t 1 in
  let result =
    if ps > 21 then "You busted! Dealer wins."
    else if ds > 21 then "Dealer busted! You win!"
    else if ps > ds then "You win!"
    else if ps < ds then "Dealer wins."
    else "Push (tie)."
  in
  Printf.sprintf "%s  Your chips: %d" result (List.hd t.chip_stacks)

let show_hand_line label hand =
  Printf.printf "%s: %s  = %d%s\n" label (Card.show_hand hand)
    (Card.hand_value hand)
    (if Card.hand_value hand > 21 then " BUST" else "")

let render (t : Table.table) phase message =
  print_endline "\n========================================";
  show_hand_line "Your hand" (List.nth t.dealt_cards 0);
  show_hand_line "Dealer   " (List.nth t.dealt_cards 1);
  List.iteri
    (fun i hand -> show_hand_line (Printf.sprintf "Player %d " (i + 1)) hand)
    (Table.drop 2 t.dealt_cards);
  Printf.printf "Bet: %d   Your chips: %d%s\n" t.current_player_bet
    (List.hd t.chip_stacks)
    (if t.user_passes then "   [PASSED]" else "");
  (match phase with
   | Hand_over msg -> Printf.printf ">>> %s\n" msg
   | Playing -> ());
  if message <> "" then Printf.printf "(%s)\n" message;
  print_endline "h:Hit  s:Stay  1:Bet10  2:Bet20  3:Bet30  n:NewHand  q:Quit"

let rec loop (t : Table.table) n phase message =
  render t phase message;
  match In_channel.input_line In_channel.stdin with
  | None | Some "q" | Some "Q" -> print_endline "Goodbye!"
  | Some cmd -> (
    let indices = List.init (n + 1) Fun.id in
    match (cmd, phase) with
    | "h", Playing ->
      let t = Table.deal_cards t indices in
      let phase = if Table.hand_over t then Hand_over (build_result_msg t) else Playing in
      loop t n phase "You hit."
    | "s", Playing ->
      let t = Table.set_player_passes t in
      let phase = Hand_over (build_result_msg t) in
      loop t n phase "You stayed."
    | "1", Playing -> loop (Table.set_player_bet 10 t) n phase "Bet set to 10"
    | "2", Playing -> loop (Table.set_player_bet 20 t) n phase "Bet set to 20"
    | "3", Playing -> loop (Table.set_player_bet 30 t) n phase "Bet set to 30"
    | "n", Hand_over _ ->
      let t = Table.initial_deal (fresh_deck ()) (Table.score_hands t) n in
      loop t n Playing "New hand dealt."
    | _ -> loop t n phase "")

let rec get_player_count () =
  print_endline
    "Besides yourself, how many other players do you want at the table? (1-4)";
  match int_of_string_opt (String.trim (input_line stdin)) with
  | Some k when k >= 1 && k <= 4 -> k + 1
  | _ ->
    print_endline "Invalid input. Please enter a number between 1 and 4.";
    get_player_count ()

let () =
  Random.self_init ();
  print_endline "Welcome to Blackjack!";
  let n = get_player_count () in
  let table = Table.initial_deal (fresh_deck ()) (Table.create_new_table n) n in
  loop table n Playing "Welcome! Use h to hit, s to stay."
