# Command Line Applications - OCaml

OCaml port of the Haskell command-line chapter: reading input, writing and
reading files, error handling, and an interactive guessing game.

## Run

```bash
dune build
dune exec ./command_line1.exe
dune exec ./command_line2.exe
dune exec ./game_loop1.exe
dune exec ./game_loop2.exe
dune exec ./read_text_file.exe
dune exec ./read_text_file_error_handling.exe
```

`command_line2` appends to `temp.txt`, which `read_text_file` then reads.

## Source files

| File | Description |
|------|-------------|
| `command_line1.ml` | echo each line upper-cased until exit/quit |
| `command_line2.ml` | same, and append each line to `temp.txt` |
| `game_loop1.ml` | guess a number 1-4, target seeded from the clock |
| `game_loop2.ml` | guess a number 1-4, target chosen at random |
| `read_text_file.ml` | read `temp.txt` and print its words |
| `read_text_file_error_handling.ml` | read a file, handling a missing-file error |
| `util.ml` | shared `read_file`, `words`, and `show_words` helpers |

## Notes on the Haskell to OCaml port

- Haskell `getLine` becomes `read_line`; end of input is `End_of_file` rather
  than an error.
- `Text.Read.readMaybe` becomes `int_of_string_opt`.
- Haskell seeded `GameLoop1` from `getPOSIXTime`; here `game_loop1` uses
  `Unix.time`, and `game_loop2` uses the standard `Random` module.
- Catching only `IOException` becomes matching `Sys_error`, keeping other
  exceptions propagating.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
