# TCP Client and Server - OCaml

OCaml port of the Haskell `network-simple` example. The server reverses every
chunk of bytes a client sends; the client sends `test123` and prints the reply.

## Run

In one terminal:

```bash
dune exec ./server.exe
```

In another:

```bash
dune exec ./client.exe
```

The client prints `Response: 321tset`.

## Notes on the Haskell to OCaml port

- Haskell `network-simple` (`T.listen`, `T.accept`, `T.recv`, `T.send`) becomes
  Lwt's `Lwt_unix` sockets, which map directly onto the BSD socket calls.
- `acceptFork` (one green thread per connection) becomes `Lwt.async` with
  `Lwt.finalize` to always close the client socket.
- The server binds to `127.0.0.1` only, matching the Haskell note about not
  exposing the service on all interfaces.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
