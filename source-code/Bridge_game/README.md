# Contract Bridge - OCaml

OCaml port of the Haskell bridge game. The engine is a faithful translation:
cards, an AI bidder with common conventions (Stayman, Blackwood, Gerber), AI
trick play, rubber scoring, and a game state machine. The console driver
auto-plays one deal end to end.

## Project layout

```
Bridge_game/
├── src/types.ml     <- suits, ranks, cards, players, bids
├── src/cards.ml      <- deck, deal, HCP, hand shape
├── src/bidding.ml    <- AI bidding (opening, responses, rebids, conventions)
├── src/play.ml       <- AI card play and trick resolution
├── src/scoring.ml    <- rubber scoring
├── src/engine.ml     <- game state and transitions
├── bin/main.ml       <- auto-play console driver
└── test/             <- Alcotest suite (ports the Haskell HSpec tests)
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe    # auto-plays one deal
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell types derived `Ord`; OCaml's polymorphic `compare` gives the same
  order because the constructors are declared low to high (and `SuitStrain`
  before `NoTrump`), so suit, rank, player, and strain comparisons match.
- `Data.Map Player [Card]` becomes `Map.Make(Player)`.
- The Haskell app had an interactive TUI; this console driver auto-plays with all
  four hands driven by the AI, which exercises the full engine deterministically.
- The tests mirror the Haskell `Spec.hs` cases for cards, bidding, and scoring.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
