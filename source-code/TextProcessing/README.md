# Text Processing - OCaml

OCaml port of the Haskell text-processing examples: clean free text and drop
stop words, and read CSV and JSON.

## Run

```bash
dune build
dune exec ./clean_text.exe
dune exec ./test_csv.exe
dune exec ./test_json.exe
```

## Source files

| File | Description |
|------|-------------|
| `clean_text.ml` | normalize whitespace and remove common stop words |
| `test_csv.ml` | read `test.csv` with the `csv` library |
| `test_json.ml` | parse JSON with Yojson |

## Notes on the Haskell to OCaml port

- Haskell's `Data.Text` operations become standard `String` functions.
- CSV reading uses the `csv` library in place of Haskell's `cassava`.
- JSON parsing uses Yojson in place of `aeson`.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
