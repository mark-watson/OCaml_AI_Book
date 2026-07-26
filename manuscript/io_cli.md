# Input/Output and Command-Line Applications

OCaml has no separate I/O type. Reading a line, opening a file, and printing to the console are ordinary function calls that you sequence with `;` or `let ... in`. That makes I/O code short and direct. This chapter covers the everyday moves: read a file, read from the console, handle a missing file, and drive an interactive loop. The code comes from two example directories, `source-code/ImPure/` and `source-code/CommandLineApp/`, which share a small `util.ml` of helpers.

## Reading a Whole File

Both directories define the same `read_file`. It opens a file, reads all of it into a string, and closes the handle even if the read fails:

```ocaml
let read_file path =
  let ic = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () -> really_input_string ic (in_channel_length ic))
```

`open_in_bin` opens the file for reading. `in_channel_length` gives its size in bytes, and `really_input_string` reads exactly that many bytes into a string. The wrapper `Fun.protect` runs the `~finally` action no matter what, so `close_in` always runs, even if reading raises. This is the OCaml pattern for "do this, and clean up afterward."

Two more helpers round out `util.ml`. `words` splits a string on any whitespace and drops the empty pieces, and `show_words` prints a string list with quotes:

```ocaml
let words s =
  s
  |> String.map (fun c -> if c = '\t' || c = '\n' || c = '\r' then ' ' else c)
  |> String.split_on_char ' '
  |> List.filter (fun w -> w <> "")
```

The `|>` pipe reads left to right: turn every whitespace character into a space, split on spaces, then keep the non-empty words.

## Mapping Over the Result of a Read

The file `source-code/ImPure/fmap_example.ml` reads a file into words and then transforms the result. Because the read just returns a list, you map an ordinary function over it:

```ocaml
let file_to_words path = Util.words (Util.read_file path)

let () =
  let file = "text1.txt" in
  if Sys.file_exists file then begin
    let ws = file_to_words file in
    print_endline (Util.show_words (List.rev ws));
    let ws2 = List.rev (file_to_words file) in
    print_endline (Util.show_words ws2)
  end
  else Printf.printf "Error: file '%s' not found.\n" file
```

`Sys.file_exists` guards the read so a missing file gives a clear message instead of an exception. `List.rev` reverses the word list. In a lazy language this would be a `fmap reverse` over an I/O action; in OCaml the read has already produced a plain list, so you reverse it like any other list.

## Words Two Files Share

The file `source-code/ImPure/common_words.ml` finds the words that appear in both of two files. It uses the standard `Set` functor, applied to the `String` module:

```ocaml
module SS = Set.Make (String)

let file_to_words path =
  Util.read_file path |> String.lowercase_ascii |> Util.words |> SS.of_list

let common_words f1 f2 =
  SS.elements (SS.inter (file_to_words f1) (file_to_words f2))
```

Each file becomes a set of lower-cased words. `SS.inter` is set intersection: the words in both. `SS.elements` returns them as a sorted list. Lowering the case first means `The` and `the` count as the same word. Sets give you intersection, union, and difference for free, which makes short work of this kind of comparison.

## Reading From the Console

Console input uses `read_line`, which returns the next line without its newline. When there is no more input, `read_line` raises `End_of_file` rather than returning an error value. To read an integer safely, parse the line with `int_of_string_opt`, which returns an `option`, and loop on bad input. From `source-code/ImPure/do_let_example.ml`:

```ocaml
let rec read_int () =
  print_endline "Enter an integer number:";
  match int_of_string_opt (String.trim (read_line ())) with
  | Some n -> n
  | None ->
    print_endline "Error: invalid integer, please try again.";
    read_int ()
```

`String.trim` drops surrounding whitespace so a stray space does not spoil the parse. `int_of_string_opt` gives `Some n` on success and `None` on junk. When it returns `None`, the function calls itself to ask again. This "parse to an option, then match" shape is how OCaml turns unsafe input into a value the type system trusts.

## An Interactive Loop

The file `source-code/CommandLineApp/command_line1.ml` reads lines and echoes them upper-cased until the user types `exit` or `quit`, or reaches end of input:

```ocaml
let rec loop () =
  print_endline "Enter a line of text for test 1 (or \"exit\"/\"quit\" to stop):";
  match read_line () with
  | exception End_of_file -> print_endline "Goodbye!"
  | ("exit" | "quit") -> print_endline "Goodbye!"
  | s ->
    Printf.printf "As upper case:\t%s\n" (String.uppercase_ascii s);
    loop ()

let () = loop ()
```

Two OCaml features do the work here. First, a `match` can catch an exception in a case with the `exception` keyword, so `read_line`'s `End_of_file` is handled right beside the normal results. Second, the pattern `("exit" | "quit")` matches either word with one case. Everything else falls to `s`, which the loop prints and then repeats.

The companion file `command_line2.ml` adds a line to a file each time through. It opens the file in append mode, creating it if needed:

```ocaml
let append_file path s =
  let oc = open_out_gen [ Open_append; Open_creat ] 0o644 path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc s)
```

`open_out_gen` takes a list of flags: `Open_append` to add to the end, `Open_creat` to create the file if it is missing, and the mode `0o644` for its permissions. As with reading, `Fun.protect` guarantees the close.

## A Guessing Game With State

The file `source-code/CommandLineApp/game_loop1.ml` asks you to guess a number from 1 to 4. It carries two pieces of state, the target and the try count, in a record:

```ocaml
type game_state = { number_to_guess : int; num_tries : int }

let rec game_loop gs =
  print_endline "Enter a number:";
  match int_of_string_opt (String.trim (read_line ())) with
  | None ->
    print_endline "Invalid input, please enter a number.";
    game_loop gs
  | Some n ->
    if n = gs.number_to_guess then gs
    else game_loop { gs with num_tries = gs.num_tries + 1 }
```

A record groups named fields. You read a field with `gs.num_tries`. You do not change it in place; instead `{ gs with num_tries = gs.num_tries + 1 }` builds a new record that copies `gs` and overrides one field. The loop passes that new state to the next call, so the try count grows without a mutable variable. When the guess is right, the loop returns the final state and the caller reports the count:

```ocaml
let () =
  let seconds = int_of_float (Unix.time ()) in
  let gs = { number_to_guess = (seconds mod 4) + 1; num_tries = 1 } in
  print_endline "Guess a number between 1 and 4";
  let final = game_loop gs in
  Printf.printf "Correct after %d tries.\n" final.num_tries
```

This version seeds the target from the clock with `Unix.time`. The companion `game_loop2.ml` is the same game with a real random target: it calls `Random.self_init ()` to seed the generator and `Random.int 4 + 1` to pick a number from 1 to 4.

## Handling a Missing File

You should catch only the error you expect, not every exception. When a file is missing or unreadable, `open_in` raises `Sys_error`. The file `source-code/CommandLineApp/read_text_file_error_handling.ml` catches just that one:

```ocaml
let safe_file_reader path =
  try Util.read_file path
  with Sys_error msg ->
    Printf.printf "Error: %s\n" msg;
    ""
```

The `try ... with` form runs the body and matches only `Sys_error`. Any other exception keeps propagating, which is what you want: a narrow catch handles the missing-file case and leaves real bugs visible. On success you get the file contents; on a missing file you get a printed message and an empty string.

## Running the Examples

Build either directory and run the programs by name:

```bash
cd source-code/CommandLineApp
dune build
dune exec ./command_line2.exe          # type lines; they append to temp.txt
dune exec ./read_text_file.exe         # read temp.txt back
dune exec ./game_loop2.exe             # play the guessing game
```

`command_line2` writes `temp.txt`, which `read_text_file` then reads, so run them in that order to see the round trip. With file reading, console input, records, sets, and narrow error handling in hand, you have the I/O toolkit the rest of the book builds on.
