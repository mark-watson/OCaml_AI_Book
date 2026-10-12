# Impure (I/O) Examples - OCaml

OCaml port of the "impure" Haskell chapter: reading input, reading files,
mapping over results, and finding the words two files share.

## Run

```bash
dune build
dune exec ./do_let_example.exe
dune exec ./do_let_example2.exe
dune exec ./do_let_example3.exe
dune exec ./fmap_example.exe
dune exec ./common_words.exe
```

`common_words` and `fmap_example` read the bundled `text1.txt` and `text2.txt`.

## Source files

| File | Description |
|------|-------------|
| `do_let_example.ml` | `let` bindings while reading input |
| `do_let_example2.ml` | same idea, running the action several times |
| `do_let_example3.ml` | prompt, read, then parse and print |
| `fmap_example.ml` | map a function over the result of reading a file |
| `common_words.ml` | words shared by two files, via `Set` intersection |
| `util.ml` | shared `read_file`, `words`, and `show_words` helpers |

## Notes on the Haskell to OCaml port

- OCaml has no `IO` monad, so Haskell's `do`, `>>=`, and applicative styles all
  become ordinary function calls. `common_words` shows one direct expression in
  place of the Haskell file's three equivalent styles.
- The Haskell `let` vs `let ... in` distinction inside `do` blocks does not exist
  in OCaml, so `do_let_example` and `do_let_example2` collapse to the same idiom.
- `Data.Set` becomes `Set.Make(String)`; `words` and `readFile` become small
  helpers in `util.ml`.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
