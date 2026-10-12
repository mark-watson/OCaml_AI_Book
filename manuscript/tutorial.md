# A Quick OCaml Tutorial

If you already write OCaml, skim this chapter for the idioms the book uses and move on. I wrote it to cover just the parts of the language you need to read, run, and change the examples that follow.

I do not try to replace the [OCaml manual](https://ocaml.org/manual/) or the excellent book [Real World OCaml](https://dev.realworldocaml.org/). I cover the basics so the later chapters read smoothly.

## Installing OCaml and the Tools

OCaml programs are built with two tools: **opam**, the package manager, and **dune**, the build system. On macOS you can install opam with Homebrew; on Linux use your package manager or the install script from [opam.ocaml.org](https://opam.ocaml.org/).

```bash
brew install opam        # macOS; see opam.ocaml.org for Linux
opam init                # one-time setup
opam switch create 5.5.1 # install a current OCaml 5.x compiler
eval $(opam env)         # put that compiler on your PATH
```

Any recent OCaml 5.x compiler works for this book. Once the switch is ready, install dune and a nice REPL called **utop**:

```bash
opam install dune utop
```

Then install the libraries the examples use. You can do this now or wait until a chapter needs one:

```bash
opam install yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest csv lambdasoup caqti caqti-lwt caqti-driver-sqlite3 dream
```

## A First Program

Every example in this book is a dune project. The smallest one is a single source file plus a **dune** file that tells the build tool what to make. Here is `source-code/pure/simple.ml`:

```ocaml
(* Basic function definition *)

let sum2 x y = x + y

let () =
  Printf.printf "1 + 2 = %d\n" (sum2 1 2)
```

A function is defined with `let name args = body`. There is no `return` keyword: the body is an expression, and its value is the result. The last block, `let () = ...`, is the program's entry point. It has type `unit` (written `()`), the type of an expression run for its effect.

The **dune** file in that directory lists the programs to build:

```
(executables
 (names simple conditionals if_then_else guards cases let_and_where
        chained_calls map_examples my_colors))
```

Build and run it:

```bash
cd source-code/pure
dune build
dune exec ./simple.exe
```

That prints `1 + 2 = 3`. Note the `.exe` suffix: dune uses it for the native binary on every platform, including macOS and Linux.

## The REPL

For quick experiments, start **utop** inside a project and type expressions. The REPL prints the value and its type, which is the fastest way to learn how a function behaves. End each phrase with `;;`.

```ocaml
$ utop
# let sum2 x y = x + y ;;
val sum2 : int -> int -> int = <fun>
# sum2 1 2 ;;
- : int = 3
# List.map (fun x -> x * x) [1; 2; 3; 4] ;;
- : int list = [1; 4; 9; 16]
```

The type `int -> int -> int` reads as "takes an int and an int, returns an int." OCaml infers these types for you; you rarely write them.

## Pattern Matching and Recursion

OCaml code takes data apart with pattern matching. The file `source-code/pure/conditionals.ml` shows the core moves over lists. A list is either empty, `[]`, or a head joined to a tail, `x :: xs`.

```ocaml
let head' = function
  | x :: _ -> x
  | [] -> failwith "head': empty list"

let tail' = function
  | _ :: xs -> xs
  | [] -> failwith "tail': empty list"

let rec double_list = function
  | [] -> []
  | x :: xs -> (2 * x) :: double_list xs
```

The keyword `function` starts a match on the last argument. Each `|` line is a case: a pattern on the left, a result on the right. The underscore `_` matches anything and binds no name. A function that calls itself needs the `rec` keyword, as in `double_list`.

You can write your own `map`. It applies a function `f` to every element:

```ocaml
let rec map' f = function
  | [] -> []
  | x :: xs -> f x :: map' f xs
```

In practice you use the standard `List.map` instead. The file also defines a `range` helper with `List.init`, which builds a list from an index function:

```ocaml
let range a b = List.init (b - a + 1) (fun i -> a + i)
```

Run the file to see all of this at work:

```bash
dune exec ./conditionals.exe
```

## if / then / else Is an Expression

In OCaml, `if` is an expression that returns a value, not a statement. Both branches must have the same type. From `source-code/pure/if_then_else.ml`:

```ocaml
let age_to_string age =
  if age < 21 then "minor" else "adult"
```

Because `if` returns a value, you use its result directly. There is no need for a separate variable to hold the answer.

## Branching and Option Values

OCaml has no guard syntax on plain definitions, so you branch with nested `if` or with `match`. The file `source-code/pure/guards.ml` shows both, and it introduces the `option` type, OCaml's safe stand-in for a missing value:

```ocaml
let spaceship n =
  if n < 0 then -1
  else if n = 0 then 0
  else 1

let random_maybe_value n =
  if n mod 2 = 0 then Some n else None

let show_opt = function
  | Some n -> "Some " ^ string_of_int n
  | None -> "None"
```

An `option` is either `Some value` or `None`. The type system forces you to handle both cases, so a missing value can never slip through as a silent null. You will see `option` throughout the book, most often as the result of a lookup that might fail. String join uses the `^` operator.

## match Expressions

The `match ... with` form is the general tool for choosing a result by shape. From `source-code/pure/cases.ml`:

```ocaml
let number_opinion n =
  match n with
  | 0 -> "Too low"
  | 1 -> "just right"
  | _ -> "OK, that is a number"
```

The compiler warns you if a match does not cover every case, which catches a whole class of bugs before the program runs.

## let Bindings for Local Values

OCaml has no `where` clause. You name intermediate values with `let ... in`. The name is in scope for the expression after `in`. From `source-code/pure/let_and_where.ml`:

```ocaml
let funny_summation w x y z =
  let bob = w + x in
  let sally = y + z in
  bob + sally
```

You can stack as many `let ... in` bindings as you like. This is how you break a long calculation into named steps.

Haskell-style list comprehensions become `List.init` or `List.map`. The comprehension `[(a, 10*a) | a <- [0..5]]` becomes:

```ocaml
let test_let_comprehension =
  List.init 6 (fun a -> (a, 10 * a))
```

That builds a list of pairs: `(0,0)`, `(1,10)`, `(2,20)`, and so on. A pair is written `(a, b)` and has type `int * int`.

## Composing and Applying Functions

Two operators help you write pipelines without extra parentheses. `@@` applies a function to an argument and is right-associative, so `f @@ g @@ x` means `f (g x)`. The pipe `|>` sends a value into a function, so `x |> f |> g` means `g (f x)`. From `source-code/pure/chained_calls.ml`:

```ocaml
let double_odd_elements =
  List.map (fun x -> if x mod 2 = 0 then x else 2 * x)

let times10_elements = List.map (fun x -> x * 10)
```

Both functions are defined by giving `List.map` just its first argument. This is partial application: a function of two arguments, given one, returns a function that wants the rest. You then chain them:

```ocaml
let new_list = times10_elements @@ double_odd_elements a_list
```

To build a reusable pipeline, compose the two functions. OCaml has no built-in compose operator, so the file defines one:

```ocaml
let compose f g x = f (g x) in
let new_list2 = (compose times10_elements double_odd_elements) a_list in
```

## The Map Functor

OCaml's standard `Map` is a functor: you apply it to a key module to get a map type for that key. The file `source-code/pure/map_examples.ml` builds a string-keyed map:

```ocaml
module StringMap = Map.Make (String)

let a_test_map =
  StringMap.of_seq (List.to_seq [ ("height", 120); ("weight", 15) ])

let get_numeric_value key a_map =
  match StringMap.find_opt key a_map with
  | Some v -> v
  | None -> -1
```

`Map.Make (String)` builds a new module, `StringMap`, whose functions all use string keys. Lookups return an `option`, so `find_opt` gives `Some v` when the key is present and `None` when it is not. This functor pattern, applying one module to another to get a new module, is one of OCaml's best features, and you will see it again with sets and databases.

## Variant Types and a Custom Order

You define your own types with variants. Each variant is a named constructor. The file `source-code/pure/my_colors.ml` defines a color type and sorts values by a rule of its own:

```ocaml
type my_colors = Orange | Red | Blue | Green | Silver

let show = function
  | Orange -> "Orange"
  | Red -> "Red"
  | Blue -> "Blue"
  | Green -> "Green"
  | Silver -> "Silver"

(* Order colors alphabetically by their name, not by constructor order. *)
let compare_colors c1 c2 = String.compare (show c1) (show c2)
```

By default OCaml compares variants by the order you declare them. Here `compare_colors` instead orders by the name text, so `List.sort compare_colors` gives Blue, Green, Orange, Red, Silver. Passing your own compare function to `List.sort` is the OCaml way to get a custom order, and Chapter 4 uses the same idea in a tested module.

## Tutorial Wrap Up

That is enough OCaml to read every example in this book. The pieces you will reach for again and again are pattern matching, the `option` type, `let ... in` bindings, the `|>` and `@@` operators, the `Map` functor, and your own variant types. The rest of the book puts them to work on real tasks. When you want more depth on the language, the [OCaml manual](https://ocaml.org/manual/) and [Real World OCaml](https://dev.realworldocaml.org/) are the places to go.
