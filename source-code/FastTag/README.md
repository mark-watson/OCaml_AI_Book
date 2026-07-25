# FastTag - OCaml

A simplified Brill part-of-speech tagger. It looks up an initial tag for each word in a static lexicon, then applies eight transformation rules to fix common cases. OCaml port of the Haskell version.

## Project layout

```
FastTag/
├── src/lexicon_data.ml  <- 92,661 word/tag records, embedded as one string
├── src/fasttag.ml       <- lexicon parsing, bigrams, and the Brill rules
├── bin/main.ml          <- tags a sample sentence
└── test/                <- Alcotest suite
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The Haskell `LexiconData.hs` held the lexicon as a `Map String String` literal. Here the same data is embedded as one tab separated record per line inside an OCaml quoted string, then parsed into a `Hashtbl` at startup. This keeps compile times fast.
- `strEndsWith` / `strStartsWith` from the `strings` package map to the standard `String.ends_with` / `String.starts_with`.
- `isInfixOf` maps to a small `contains_substring` helper.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
