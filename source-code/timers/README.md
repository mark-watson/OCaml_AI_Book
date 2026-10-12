# Timers - OCaml

OCaml port of the Haskell timing example. It benchmarks a prime sieve and shows
how to put a hard time limit on a computation.

## Run

```bash
dune build
dune exec ./timer_test.exe
```

## Notes on the Haskell to OCaml port

- Haskell `getPOSIXTime` becomes `Unix.gettimeofday`.
- Haskell `timeIt` becomes a small `time_it` helper that prints elapsed seconds.
- Haskell `timeout` (which uses async exceptions on a green thread) becomes a
  `timeout` built on `Unix.setitimer` with a `SIGALRM` handler that raises. The
  signal is delivered at allocation points, so the allocating sieve can be cut
  off mid-run, matching the Haskell behaviour.
- Infinite lists `[2..]` and `[0..]` become `Seq.ints`.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
