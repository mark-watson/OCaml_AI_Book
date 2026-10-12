# Bridge Web UI - OCaml

OCaml port of the Haskell `Bridge_webkit` app: a browser UI for playing rubber
bridge against the AI, built on the same engine as the `bridge_game` example.
The Haskell version ran in a native WebKit window; this port serves the identical
`app/index.html` from a [Dream](https://aantron.github.io/dream/) server, keeping
the JS bridge (`window.webkit_haskell.invoke`).

## Project layout

```
bridge_webkit/
├── src/
│   ├── types.ml, cards.ml, bidding.ml, play.ml, scoring.ml, engine.ml  <- bridge engine
│   ├── parsing.ml   <- parse typed bids
│   └── payload.ml   <- marshal game state to the frontend's JSON shape
├── app/index.html   <- the UI (reused from the Haskell app)
├── bin/main.ml      <- Dream server, game state, and the six bridge handlers
└── test/            <- Alcotest over parsing and the state payload
```

## Build and run

Run from the project root so `app/index.html` resolves:

```bash
dune build
dune exec ./bin/main.exe    # then open http://127.0.0.1:8080/
dune runtest
```

You bid and play as South; the other three seats are played by the AI. Type bids
like `1H`, `2NT`, `Pass`, or `X`.

## Notes on the Haskell to OCaml port

- The bridge engine modules are shared with `bridge_game`.
- The native WebKit window becomes a Dream server; `registerHandler` commands
  (`get-state`, `bid`, `play-card`, `ai-play-single`, `next-deal`, `reset-game`)
  become `/bridge/<command>` POST routes.
- `makePayload` is reproduced field for field so the reused `index.html` works
  unchanged (JSON keys like `hlNorth`, `bePlayer`, `pcCard`, `nsBelow`).
- `System.Random` `splitGen` becomes a threaded integer seed.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
