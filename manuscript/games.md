# AI for Games

Games are a classic proving ground for AI, and they exercise OCaml in ways the earlier chapters do not: game state that changes over many turns, rules that must be exactly right, and agents that choose moves. This chapter covers three games of rising difficulty. Blackjack, in `source-code/blackjack/`, shows immutable game state threaded through a console loop. Contract bridge, in `source-code/bridge_game/`, adds an AI that bids and plays. Go, in `source-code/go_playing_program/`, builds a full board engine with captures, ko, and scoring, plus a self-play agent.

A common thread runs through all three: the game state is an immutable record, and each move returns a new state rather than changing the old one. This is the OCaml way to write a game, and it makes the rules easy to test.

## Blackjack

The card model in `src/card.ml` is pure data. Suits and ranks are variant types, a card is a record, and the deck is built by pairing every rank with every suit:

```ocaml
type suit = Hearts | Diamonds | Clubs | Spades
type rank = Two | Three | ... | King | Ace
type card = { rank : rank; suit : suit }

let ordered_card_deck =
  List.concat_map
    (fun r -> List.map (fun s -> { rank = r; suit = s }) all_suits)
    all_ranks
```

`List.concat_map` runs a function that returns a list over each rank and flattens the result, so the two nested maps produce all 52 cards. Card values come from a simple match, with the hand value a fold:

```ocaml
let hand_value cs = List.fold_left (fun acc c -> acc + card_value c) 0 cs
```

Shuffling, in `src/shuffle.ml`, is the Fisher-Yates algorithm. It is the one place the game uses a mutable array, because the swap is clearest that way:

```ocaml
let shuffle lst =
  let a = Array.of_list lst in
  for i = Array.length a - 1 downto 1 do
    let j = Random.int (i + 1) in
    let tmp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- tmp
  done;
  Array.to_list a
```

The game state lives in `src/table.ml` as one record: the chip stacks, the cards dealt to each player, the current bet, and the deck. Player 0 is the human, player 1 is the dealer, and 2 and up are AI players. Because OCaml records do not change in place, updating one field means building a new record with `{ t with ... }`. Since the cards are a list of hands, the file adds a small helper to replace one element:

```ocaml
let list_set i v lst = List.mapi (fun j x -> if j = i then v else x) lst
```

Dealing a card shows the pattern. It takes the top card off the deck and prepends it to a player's hand, returning a new table:

```ocaml
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
```

The AI rule is one line on top of that: the human always draws when asked, but an AI player draws only while its hand is under 17, the standard dealer rule:

```ocaml
let deal_card_to_user t player_index =
  if player_index = 0 then deal_card_to_user' t player_index
  else if score t player_index < 17 then deal_card_to_user' t player_index
  else t
```

Dealing to several players is a fold that threads the table through each one:

```ocaml
let deal_cards t player_indices =
  List.fold_left deal_card_to_user t player_indices
```

Because every function takes a table and returns a new one, the whole game is a chain of pure transforms. The console front end in `bin/main.ml` reads a key, applies the matching transform, and prints the new table. Play it:

```bash
cd source-code/blackjack
dune build
dune exec ./bin/main.exe
```

The controls are `h` to hit, `s` to stay, `1`/`2`/`3` to bet, `n` for a new hand, and `q` to quit.

## Contract Bridge

Bridge is a big step up. The engine in `bridge_game/` deals hands, runs an auction where an AI bids using real conventions, plays out all thirteen tricks with an AI, and scores the result. It is split into modules for types, cards, bidding, play, scoring, and the engine state machine.

The types in `src/types.ml` are ordinary variants, but their order is deliberate. OCaml's built-in `compare` orders variants by declaration order, so the constructors are listed low to high on purpose, and the engine gets correct card and bid comparisons for free:

```ocaml
type suit = Clubs | Diamonds | Hearts | Spades
type rank = R2 | R3 | ... | King | Ace
type player = North | East | South | West
type strain = Suit_strain of suit | No_trump
type bid_type = Suit_bid of int * strain | Pass | Double_bid | Redouble_bid
type phase = Dealing | Bidding | Playing | Scoring | Done
```

The `phase` type is the game's state machine: a deal moves from `Dealing` to `Bidding` to `Playing` to `Scoring` to `Done`. Hand evaluation, in `src/cards.ml`, is where bridge knowledge lives. High card points are the familiar 4-3-2-1 for ace-king-queen-jack:

```ocaml
let card_hcp c =
  match c.rank with Ace -> 4 | King -> 3 | Queen -> 2 | Jack -> 1 | _ -> 0

let hand_hcp hand = List.fold_left (fun a c -> a + card_hcp c) 0 hand
```

A hand's shape is the length of each suit, and a hand is balanced when its sorted shape is one of the flat patterns:

```ocaml
let is_balanced hand =
  let sh = hand_shape_sorted hand in
  sh = [ 4; 3; 3; 3 ] || sh = [ 4; 4; 3; 2 ] || sh = [ 5; 3; 3; 2 ]
```

There is more: length points, shortness points, whether a suit has a stopper, and honor counts. These are the inputs a human bridge player uses, and the AI bidder in `src/bidding.ml` uses them to choose openings, responses, and rebids, including the common conventions Stayman, Blackwood, and Gerber. The play module chooses a card to follow suit, win a trick, or discard, and the scoring module keeps rubber score.

The console driver in `bin/main.ml` runs one full deal with all four seats played by the AI. It reads whose turn it is from the engine, asks the AI for a bid or a card, and applies it, looping until the phase changes:

```ocaml
while !gs.phase = Bidding do
  match Engine.current_actor !gs with
  | Some actor ->
    let hand = Engine.PMap.find actor !gs.hands in
    let bid = Bidding.ai_select_bid hand !gs.bid_history actor !gs.dealer in
    Printf.printf "%-6s %s\n" (show_player actor) (show_bid bid);
    gs := Engine.apply_bid bid !gs
  | None -> gs := { !gs with phase = Done }
done;
```

`Engine.PMap` is a `Map` keyed by player, so `PMap.find actor !gs.hands` gets a player's cards. The state `gs` is a `ref` holding the immutable game record; each `apply_bid` returns a new record that replaces it. Run a full deal:

```bash
cd source-code/bridge_game
dune build
dune exec ./bin/main.exe    # auto-plays one deal
dune runtest
```

The program prints the four hands, the auction bid by bid, the contract, the play trick by trick, and the final score. There is also a web version in `source-code/bridge_webkit/` that serves the same engine through a Dream server, using the JavaScript bridge from Chapter 11 so you can bid and play as South against the AI.

## Go

Go has simple rules and deep play. The engine in `src/board.ml` gets the rules exactly right: captures, suicide, the ko rule, legal moves, area scoring, and eye detection. The board is a flat integer array, 0 for empty, 1 for black, 2 for white, and it is persistent: every move copies the array, so an old board is never changed:

```ocaml
type board = {
  grid : int array;
  sz : int;
  to_move : color;
  prev_hash : int;      (* hash of the position before the last move, for ko *)
  last_move : int option;
  captures : int * int;
}
```

Two ideas drive the rules, and the figure shows both. Stones of one color that touch along the grid lines form a **group**, and a group's **liberties** are the empty points next to it. A group with no liberties is captured. An **eye** is an empty point a group surrounds on its own. White cannot play into an eye, because the stone would have no liberties, so a group with two eyes never loses its last liberty and can never be captured.

![Left: a white group and its liberties. Right: a black group with two eyes.](images/go_liberties_eyes.png)

Finding a group is a flood fill with an explicit stack, so it never overflows on a big board:

```ocaml
let flood_group grid sz color seed =
  let rec go stack seen acc =
    match stack with
    | [] -> acc
    | x :: xs ->
      if ISet.mem x seen then go xs seen acc
      else if grid.(x) <> color then go xs seen acc
      else go (neighbors_raw sz x @ xs) (ISet.add x seen) (x :: acc)
  in
  go [ seed ] ISet.empty []
```

Playing a stone is where the rules come together. `try_play_idx` returns an `option`: `Some new_board` for a legal move, `None` for an illegal one. It places the stone, removes any enemy groups it captures, and then checks two rules:

```ocaml
let try_play_idx b i =
  if b.grid.(i) <> 0 then None
  else begin
    ...
    let trial1, removed = remove_dead_groups trial0 sz enemy (neighbors_raw sz i) in
    let own_libs = count_libs_of trial1 sz (flood_group trial1 sz color i) in
    if own_libs = 0 then None (* suicide *)
    else
      let new_hash = hash_grid trial1 in
      if b.prev_hash <> 0 && new_hash = b.prev_hash then None (* ko *)
      else Some { grid = trial1; ... }
  end
```

Two illegal moves fall out cleanly. A move that leaves your own group with no liberties is suicide, so it returns `None`. A move that recreates the position before the last move breaks the ko rule; the board keeps a hash of the previous position, and if the new position hashes to the same value, the move is `None`. Returning an `option` means the caller cannot forget to check: an illegal move has no board to play on.

Scoring uses the Chinese area method: your stones plus the empty territory only your color surrounds. `compute_territory` floods each empty region and checks which colors touch it, and `area_score` adds stones and territory from Black's view.

The agent in `src/agent.ml` is deliberately light. It plays a legal move, prefers moves that capture, and never fills its own eyes, which keeps its groups alive and makes self-play end:

```ocaml
let choose_move b =
  let candidates =
    List.filter
      (fun i ->
        b.grid.(i) = 0
        && (not (is_own_eye b i b.to_move))
        && try_play_idx b i <> None)
      (List.init (b.sz * b.sz) Fun.id)
  in
  match candidates with
  | [] -> Pass
  | _ ->
    let capturing =
      List.filter
        (fun i ->
          match try_play_idx b i with
          | Some b' -> total_captures b' > total_captures b
          | None -> false)
        candidates
    in
    let pick lst = List.nth lst (Random.int (List.length lst)) in
    let i = match capturing with [] -> pick candidates | _ -> pick capturing in
    Play (row_of b i, col_of b i)
```

The candidate moves are the empty points that are legal and are not the agent's own eyes. If any candidate captures, the agent picks from those; otherwise it picks any candidate at random. Avoiding its own eyes is the key to termination: a group with two eyes is alive, and by refusing to fill them the agent leaves both groups standing, so the game reaches a natural end instead of self-destructing.

The game loop lives in `src/selfplay.ml`. `Selfplay.play_game` starts from an empty board and asks the agent for moves until there are two passes in a row or a move cap is reached, then returns the final board and the move count. The driver in `bin/main.ml` plays one game and prints the board and the score:

```bash
cd source-code/go_playing_program
dune build
dune exec ./bin/main.exe
dune runtest
```

It prints the final board with `X` for black and `O` for white, the capture counts, and the area score. The full Go program this was ported from had a much larger AI stack with Monte Carlo tree search and joseki libraries; this port keeps the complete, correct board engine and a simple agent, which is enough to play and score a real game. That split is a good lesson: get the rules exactly right in a small, tested engine, and you can grow the intelligence on top of it later.

### Parallel Playouts with Domains

One way to grow that intelligence starts with **playouts**. A playout plays a game from some position to the end with a fast, light policy like our agent, and records who won. One playout says little. Thousands of them, averaged, give a usable estimate of how good a position is, and that estimate is the core of Monte Carlo tree search, the method behind the strongest Go programs before deep learning.

Playouts also suit parallel hardware well. Each game is independent, and because our boards are persistent, two games never touch the same memory. OCaml 5 can run them truly in parallel with **domains**. A domain is an OCaml thread of execution that runs on its own CPU core with its own minor heap. `Domain.spawn f` starts `f` on a new domain and returns a handle, and `Domain.join` waits for it and returns `f`'s result.

The program in `bin/playouts.ml` tallies the results of a batch of games:

```ocaml
type tally = { black : int; white : int; draws : int }

let run_games n =
  let rec loop i t =
    if i = 0 then t
    else
      let final, _ = Selfplay.play_game () in
      loop (i - 1) (add t (Selfplay.result_of final))
  in
  loop n empty
```

To run in parallel, it splits the games into one share per domain. It spawns a worker domain for every share but the first, runs the first share on the current domain so that domain does useful work too, then joins the workers and merges the tallies:

```ocaml
let run_parallel ~domains n =
  let share k = (n / domains) + if k < n mod domains then 1 else 0 in
  let workers =
    List.init (domains - 1) (fun k ->
        Domain.spawn (fun () -> run_games (share (k + 1))))
  in
  let mine = run_games (share 0) in
  List.fold_left (fun t w -> merge t (Domain.join w)) mine workers
```

There are no locks anywhere. Each domain builds its own tally, and results move between domains only through `Domain.join`'s return value. Parallel code built this way, with independent work and results merged at the end, cannot have data races. The one piece of shared machinery is the random number generator the agent uses, and OCaml 5 already gives each domain its own `Random` state, split from its parent's when the domain is spawned.

`Domain.recommended_domain_count ()` reports how many domains the machine can run well, usually its core count. Spawning many more domains than that makes the program slower, not faster. The program times a sequential run and a parallel run of the same number of games:

```bash
cd source-code/go_playing_program
dune exec ./bin/playouts.exe -- 400
```

On a 15-core laptop it printed:

```
400 playouts on 9x9, 15 domains available
sequential             Black 224  White 176  Draw  0   4.19s
parallel (15 domains)  Black 189  White 211  Draw  0   0.68s
speedup: 6.2x
```

The tallies differ between the two runs because the games are random. What matters is the speedup: a little over six times faster on 15 domains. It is less than 15 because the cores share memory bandwidth and the garbage collector does some work in coordinated pauses across all domains. That is typical for allocation-heavy code like this engine, which copies the board on every move. The test suite checks the parallel path as well, running games on three domains and making sure every result comes back.

With a fast, parallel playout function, the next step toward a real Go player is a search that spends its playouts on the most promising moves. That search is Monte Carlo tree search, and it is a good project to build on this engine.
