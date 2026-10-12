# Testing OCaml Code with Alcotest

Every example in this book ships with tests, and they all use the same library: [Alcotest](https://github.com/mirage/alcotest), a small, clear test framework. This chapter shows the pattern with the example in `source-code/testing/`: a tiny library module and a test suite over it. Once you see the shape here, every other test directory in the book will read the same way.

## Project Layout: Library, Program, and Tests

A dune project splits into three parts, each in its own directory with its own `dune` file:

```
testing/
├── src/my_colors.ml    <- the library implementation
├── src/my_colors.mli   <- the library's public interface
├── bin/main.ml         <- a program that uses the library
└── test/               <- the Alcotest suite
```

The `src/dune` file declares a library:

```
(library
 (name my_colors))
```

The `test/dune` file declares a test that depends on that library and on Alcotest:

```
(test
 (name test_my_colors)
 (libraries my_colors alcotest))
```

Keeping the real code in a library, separate from the program and the tests, is worth the small extra structure. Both the program and the test suite link against the same library, so you test the exact code you ship.

## The Interface File

The file `src/my_colors.mli` is an interface. It lists the types and functions the module makes public. Anything not listed stays private, which keeps a module's surface small and its internals free to change:

```ocaml
type t = Orange | Red | Blue | Green | Silver

val show : t -> string

(* Alphabetical by constructor name, like the Haskell custom Ord instance. *)
val compare : t -> t -> int
val equal : t -> t -> bool
val ( < ) : t -> t -> bool
val ( > ) : t -> t -> bool
```

Each `val` line gives a name and its type. Note the last two: this module exports its own `<` and `>` operators, so callers can compare colors with the same symbols they use on numbers.

## The Implementation

The file `src/my_colors.ml` provides a body for every `val` in the interface. The color type orders its values by name text rather than by declaration order:

```ocaml
type t = Orange | Red | Blue | Green | Silver

let show = function
  | Orange -> "Orange"
  | Red -> "Red"
  | Blue -> "Blue"
  | Green -> "Green"
  | Silver -> "Silver"

(* Custom order: alphabetical by constructor name. *)
let compare a b = String.compare (show a) (show b)

let equal a b = compare a b = 0
let ( < ) a b = compare a b < 0
let ( > ) a b = compare a b > 0
```

Because `compare` sorts by the `show` text, the order is alphabetical: Blue, Green, Orange, Red, Silver. The `<` and `>` operators are defined on top of `compare`, so they follow the same rule. The program in `bin/main.ml` shows this with a local open:

```ocaml
let () = Printf.printf "%b\n" My_colors.(Red < Green)
```

The form `My_colors.(...)` opens the module just for the expression in the parentheses, so `<` there means `My_colors.( < )`. With alphabetical order, "Green" sorts before "Red", so `Red < Green` is `false`, and the program prints `false`.

## Writing Tests

The file `test/test_my_colors.ml` holds the suite. A test is a function of type `unit -> unit` that makes one or more checks. The core check is `Alcotest.check`, which takes a *testable* (a description of how to compare and print a type), a message, the expected value, and the actual value:

```ocaml
let test_head () =
  Alcotest.(check int) "first Int" 1 (List.hd [ 1; 2; 3; 4 ]);
  Alcotest.(check string) "first string" "the" (List.hd [ "the"; "dog"; "ran" ])
```

`Alcotest.(check int)` opens the Alcotest module so `int` names the built-in testable for integers; `check string` and `check bool` work the same way. If the expected and actual values differ, Alcotest prints both and fails the case.

To test that code raises an exception, use `check_raises`. It runs a function and checks that it throws the exact exception you name:

```ocaml
let test_head_empty () =
  Alcotest.check_raises "empty list raises"
    (Failure "hd") (fun () -> ignore (List.hd ([] : int list)))
```

`List.hd` on an empty list raises `Failure "hd"`, so this case passes. The type annotation `([] : int list)` tells the compiler which empty list this is, since `[]` alone is polymorphic.

The color tests check the custom order:

```ocaml
let test_descending () =
  Alcotest.(check bool) "Green < Red" true My_colors.(Green < Red)

let test_ascending () =
  Alcotest.(check bool) "Red > Silver is false" false My_colors.(Red > Silver)
```

"Green" sorts before "Red", so `Green < Red` is `true`. "Red" does not sort after "Silver", so `Red > Silver` is `false`. Both checks confirm the alphabetical rule.

## Running the Suite

The `main` function names the suite and groups the cases. `Alcotest.run` takes a suite name and a list of groups; each group is a name and a list of `test_case` values:

```ocaml
let () =
  Alcotest.run "MyColors"
    [ ( "head",
        [ Alcotest.test_case "returns the first element" `Quick test_head;
          Alcotest.test_case "throws on empty list" `Quick test_head_empty ] );
      ( "MyColors",
        [ Alcotest.test_case "custom compare descending" `Quick test_descending;
          Alcotest.test_case "custom compare ascending" `Quick test_ascending ] );
    ]
```

`test_case` takes a label, a speed level (`` `Quick `` or `` `Slow `` so you can skip slow tests when you want a fast run), and the test function. Run the whole thing with:

```bash
cd source-code/testing
dune runtest
```

Alcotest prints one line per case and a summary. On a failure it shows the group, the case, and the expected against the actual value, so you can jump straight to the problem. Every example in this book responds to `dune runtest`, and now you can read any of those suites: they all use the `check`, `check_raises`, `test_case`, and `run` pieces you just saw.
