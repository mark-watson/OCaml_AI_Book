# Go Playing Program - OCaml

OCaml port of the Haskell Go program. The `Board` engine is a faithful
translation: captures, suicide, ko, legal moves, Chinese-style area scoring, and
eye detection. A light agent plays legal, capture-seeking moves without filling
its own eyes, and the driver self-plays a full 9x9 game.

## Project layout

```
Go_playing_program/
├── src/board.ml   <- board, captures, ko, suicide, scoring, eyes
├── src/agent.ml   <- capture-seeking, eye-avoiding move selection
├── bin/main.ml    <- 9x9 self-play driver
└── test/          <- Alcotest suite (ports the Haskell Board spec, plus a capture test)
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell `Board` used an unboxed `Data.Vector` and `Data.IntSet`; here the
  grid is a flat `int array` (boards stay persistent by copying on write) and
  groups use `Set.Make(Int)`.
- The full Haskell program also had `Rules`, `Tactical`, `Strategic`, `Joseki`,
  `MCTS`, and `Agent` modules (a large AI stack, about 3000 further lines). This
  port keeps the complete board engine and a simpler agent, which is enough to
  play and score a full game. The heavy search AI is not ported.
- The tests mirror the Haskell `Spec.hs` board cases and add a capture test.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
