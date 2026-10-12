# Blackjack - OCaml

OCaml port of the Haskell Blackjack game. The pure engine (cards, shuffle, and
table rules) is a faithful translation; the terminal UI is a console loop.

## Project layout

```
blackjack/
├── src/card.ml     <- ranks, suits, ordered deck, point values
├── src/shuffle.ml  <- Fisher-Yates shuffle
├── src/table.ml    <- game state and rules
├── bin/main.ml     <- console front end
└── test/           <- Alcotest over the engine
```

## Build and play

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

Controls: `h` hit, `s` stay, `1`/`2`/`3` bet 10/20/30, `n` new hand, `q` quit.

## Notes on the Haskell to OCaml port

- The Haskell version had a Brick terminal UI. The OCaml standard stack has no
  Brick equivalent, so the UI here is a plain text loop with the same controls.
- Haskell lenses (`over`, `element i .~ v`) become record-update plus a small
  `list_set` helper.
- Player indexing is unchanged: 0 = human, 1 = dealer, 2+ = AI players. As in the
  original, a hand ends only when the player stays.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
