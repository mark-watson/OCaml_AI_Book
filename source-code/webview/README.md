# Web View Apps - OCaml

OCaml port of the Haskell `webkit-haskell` examples. The Haskell library opened a
native WebKit window and let JavaScript call registered handlers over a C bridge
(`window.webkit_haskell.invoke`). There is no clean WebKitGTK binding in the
OCaml stack, so this port keeps the same JS API but runs it as a
[Dream](https://aantron.github.io/dream/) web app: the page loads in a browser
and `invoke()` POSTs to `/bridge/<command>`.

## Project layout

```
webview/
├── lib/webview.ml  <- the bridge host (register handlers, serve page + bridge.js)
├── bin/counter.ml  <- counter app (increment/decrement/reset over the bridge)
├── bin/hello.ml    <- hello-world app
└── test/           <- Alcotest over handler dispatch
```

## Build and run

```bash
dune build
dune exec ./bin/counter.exe   # then open http://127.0.0.1:8080/
dune exec ./bin/hello.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The C FFI to a Cocoa/WebKit window becomes a Dream server; `newWebKitApp`,
  `registerHandler`, `loadHTML`, and `runWebKitApp` become `create`, `register`,
  the `~page` argument, and `run`.
- The JS shim `window.webkit_haskell.invoke(cmd, payload)` is preserved, so the
  page code is nearly identical; it now `fetch`es `/bridge/<cmd>` instead of
  crossing a native bridge.
- Handlers take and return `Yojson` values, matching the Haskell `Aeson.Value`.
- The Haskell MarkdownViewer example is not ported (it needs a markdown renderer).

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
