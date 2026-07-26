# Web Chat - OCaml

OCaml port of the Haskell Scotty chat app. It serves a one-page chat UI and
forwards each prompt to the Gemini API. The Haskell version used Scotty; this
one uses [Dream](https://aantron.github.io/dream/).

## Setup

```bash
export GOOGLE_API_KEY=your-key-here
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
```

Then open `http://127.0.0.1:3000/`.

```bash
dune runtest
```

## Project layout

```
webchat/
├── lib/chat.ml   <- Gemini codec, prompt parsing, and the HTML page
├── bin/main.ml   <- the Dream server and the outbound API call
└── test/         <- Alcotest over the codec
```

## Notes on the Haskell to OCaml port

- Scotty's `get "/"` and `post "/chat"` become `Dream.get`/`Dream.post` inside a
  `Dream.router`.
- `jsonData`/`json` become `Dream.body` plus Yojson; the reply keeps the
  `{ "text": ... }` shape the page's JavaScript expects.
- The pure codec lives in `chat.ml` so the tests need no server or API key.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
