# Testing - OCaml

OCaml port of the Haskell testing example. A small `My_colors` module with a
custom ordering, plus a unit test suite. The Haskell version used HSpec; here we
use Alcotest.

## Project layout

```
TestingHaskell/
├── src/my_colors.ml   <- color type with alphabetical-by-name ordering
├── bin/main.ml        <- prints `Red < Green`
└── test/              <- Alcotest suite
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell `instance Ord MyColors` compared colors by their `show` text. Here
  `My_colors.compare` compares by `show` the same way, so the order is
  alphabetical: Blue, Green, Orange, Red, Silver.
- HSpec `describe`/`it`/`shouldBe` becomes Alcotest `test_case` plus `check`.
- `shouldThrow anyException` becomes `Alcotest.check_raises`; `List.hd []` raises
  `Failure "hd"`.
- The Haskell suite included one deliberately wrong assertion to show failure
  output. That case is corrected here so `make test` passes for the whole book.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
