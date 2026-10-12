# Functional Patterns: State, Laziness, Timing, and Debugging

OCaml gives you a lot for free, but a few patterns that other functional languages build in you write yourself. That is a feature: the pieces are small, and seeing them in full teaches you how they work. This chapter builds three of them: a `State` module for threading state through pure code (then the same thing again with OCaml 5 effect handlers), lazy sequences for streams you compute on demand, and a timeout that can cut off a long computation. Along the way you get a trace helper for debugging and a small benchmark timer.

## A State Module

Some functional languages ship a `State` monad that carries a value through a chain of steps without a mutable variable. OCaml has no such built-in, so `source-code/state_monad/state1.ml` defines one. The whole module is under twenty lines:

```ocaml
module State = struct
  type ('s, 'a) t = 's -> 'a * 's

  let return x s = (x, s)
  let bind m f s =
    let a, s' = m s in
    (f a) s'

  (* let* enables do-notation style sequencing *)
  let ( let* ) = bind
  let ( >>= ) = bind
  let ( >> ) m1 m2 = bind m1 (fun _ -> m2)

  let get s = (s, s)
  let put n _ = ((), n)

  let run_state (m : ('s, 'a) t) s = m s
  let eval_state (m : ('s, 'a) t) s = fst (m s)
  let exec_state (m : ('s, 'a) t) s = snd (m s)
  let map_state f (m : ('s, 'a) t) s = f (m s)
end
```

The key line is the type. A stateful computation of type `('s, 'a) t` is a function from a starting state to a pair of a result and a new state. Nothing runs until you hand it a start state.

- `return x` yields `x` and leaves the state alone.
- `bind m f` runs `m`, takes its result `a` and new state `s'`, then runs `f a` from `s'`. It chains two steps so the state flows from the first into the second.
- `get` reads the current state as the result. `put n` throws the old state away and installs `n`.
- `run_state` runs a computation and returns both the value and the final state. `eval_state` keeps only the value; `exec_state` keeps only the state.

### do-notation with let*

OCaml lets you name a binding operator `let*`. When you write `let* x = m in ...`, the compiler rewrites it to `bind m (fun x -> ...)`. That gives you clean sequencing without a pile of nested functions:

```ocaml
open State

(* Increment the state, returning the old value. do-notation style. *)
let increment_state =
  let* n = get in
  let* () = put (n + 1) in
  return n
```

Read it top to bottom: get the state into `n`, put `n + 1` back, then return the old `n`. The state threads through for you. The same computation with the raw operators is shorter but harder to read:

```ocaml
let increment_state2 = get >>= fun a -> put (a + 1) >> return a
```

Both forms are the same function. `map_state` transforms the whole `(value, state)` pair at the end:

```ocaml
let bump_vals (a, b) = (a + 1, b + 2)
```

Running the demos gives:

```
(1,2)
(1,2)
(2,4)
1
2
```

The first two lines are the two `increment_state` versions: start at 1, return the old value 1, leave state 2. The third applies `bump_vals` to `(1, 2)` to get `(2, 4)`. The last two show `eval_state` (the value, 1) and `exec_state` (the state, 2). This `State` module is enough for any place you want to pass state through pure code without a global.

## The Same State with Effect Handlers

The `State` module is the classic functional answer, and it works in any version of OCaml. OCaml 5 adds a second answer: **effect handlers**. An effect is like an exception that can be resumed. Code *performs* an effect to ask a question, a *handler* further up the call stack answers it, and the code carries on from where it stopped with the answer in hand. State is the standard first example, so `source-code/state_monad/state_effects.ml` rebuilds the previous section's program with effects.

First declare the effects. `Effect.t` is an extensible type, so you add constructors to it the way you would add exceptions. The type parameter is the type of the answer: `Get` is answered with a state, `Put` with unit. The functor lets one definition work for any state type:

```ocaml
module State (S : sig type t end) = struct
  type _ Effect.t += Get : S.t Effect.t | Put : S.t -> unit Effect.t

  let get () = Effect.perform Get
  let put n = Effect.perform (Put n)
```

Now `get` and `put` are ordinary functions. They perform an effect and return its answer. The handler that supplies the answers is `run_state`:

```ocaml
  let run_state (f : unit -> 'a) (init : S.t) : 'a * S.t =
    let step =
      match f () with
      | v -> fun s -> (v, s)
      | effect Get, k -> fun (s : S.t) -> Effect.Deep.continue k s s
      | effect (Put s'), k -> fun _ -> Effect.Deep.continue k () s'
    in
    step init
```

A `match` with `effect` cases, new syntax in OCaml 5.3, runs `f ()` and installs a handler around it. The first case handles a normal return. Each `effect` case runs when `f` performs that effect, and it receives `k`, the **continuation**: the rest of `f`'s computation, paused at the `perform`. `Effect.Deep.continue k x` resumes it with `x` as the answer.

The handler reuses the monad's idea: every case returns a function from a state to a `(result, state)` pair, which is the monad's `('s, 'a) t` type, so the state is threaded through without a mutable variable:

- On a normal return with value `v`, the final step is `fun s -> (v, s)`.
- On `Get`, the step receives the current state `s`, resumes the computation with `s` as `get`'s answer, and passes `s` on unchanged to whatever comes next. That is why `s` appears twice.
- On `Put s'`, the step ignores the old state, resumes with `()`, and passes the new state `s'` along.

These are **deep** handlers: when `continue k` resumes the computation, the same handler is still installed around it, so the next `get` or `put` lands back in `run_state`. The `(s : S.t)` annotation is needed because inside an `effect` case the type checker knows the answer type only locally, and the annotation tells it which state type the step takes. `eval_state`, `exec_state`, and `map_state` are one-liners on top of `run_state`, as before.

The gain is in how you write stateful code. Here is `increment_state` again:

```ocaml
module IntState = State (struct type t = int end)
open IntState

let increment_state () =
  let n = get () in
  put (n + 1);
  n
```

There is no `let*`, no `return`, and no special type. It is plain sequential OCaml, and it gives the same results as the monadic version:

```
(1,2)
(2,4)
1
2
```

The bigger difference shows up when stateful code meets ordinary library functions. `List.iter` knows nothing about state, but with effects its callback can still use `get` and `put`:

```ocaml
let count_long_words words =
  List.iter (fun w -> if String.length w > 3 then put (get () + 1)) words
```

Running `exec_state (fun () -> count_long_words [...]) 0` on five words prints `long words: 3`. With the monad you cannot pass a stateful step to `List.iter`, because `List.iter` expects a function returning `unit`, not a `('s, unit) t`. You would have to write a monadic `iter` first, and a monadic version of every other higher-order function you want to use. Effect handlers exist to solve this problem: monadic types that spread through a code base.

So which should you use? The comparison comes down to a few points:

- **Types.** The monad puts state in the type, so `('s, 'a) t` tells a reader the function is stateful. With effects, `increment_state` has type `unit -> int`, and nothing in the type says it needs a handler. If you call it without one, OCaml raises `Effect.Unhandled` at run time.
- **Composition.** Effects compose with existing code, as `List.iter` showed. The monad needs its own version of each combinator.
- **Portability.** The monad is plain functions and works on any OCaml. Effects need OCaml 5, and the `effect` pattern syntax needs 5.3 or later.

For a small, self-contained computation the monad is clear and explicit. When state, or another effect such as logging, a generator, or cooperative scheduling, has to pass through code you did not write, effect handlers are the OCaml 5 way to do it. Concurrency libraries such as Eio use them to implement lightweight threads.

Run both versions from the project directory:

```bash
cd source-code/state_monad
dune exec ./state1.exe
dune exec ./state_effects.exe
```

## Lazy Sequences and Trace Debugging

The next two examples share a tool: OCaml's `Seq`, a lazy sequence you compute one element at a time. A `Seq.t` is a function you call to get the next element, so an "infinite" sequence like `Seq.ints 2` (2, 3, 4, ...) is fine: you only ever force the part you take.

The file `source-code/debugging/trace_timer.ml` uses a lazy prime sieve to show how to print debug output from otherwise pure code. First the trace helper. Other functional languages have a built-in trace; here it is one line:

```ocaml
let trace msg x = Printf.eprintf "%s\n%!" msg; x
```

It prints `msg` to stderr and returns `x` unchanged, so you can drop it into any expression without changing the result. The `%!` flushes stderr right away, so trace lines never sit in a buffer past the moment they fire.

The sieve of Eratosthenes builds primes lazily:

```ocaml
let rec sieve seq () =
  match seq () with
  | Seq.Nil -> Seq.Nil
  | Seq.Cons (p, rest) ->
    Printf.eprintf "     -- inside sieve recursion\n%!";
    Seq.Cons (p, sieve (Seq.filter (fun y -> y mod p <> 0) rest))
```

A `Seq.t` is a function of `unit`, so `sieve seq ()` returns either `Seq.Nil` (empty) or `Seq.Cons (p, rest)` (a head `p` and a tail `rest`). The sieve keeps the head prime `p` and filters every later multiple of `p` out of the tail. Because the tail is lazy, no work happens until something asks for the next prime.

That "asks for the next" is the point of the example. OCaml is strict, so a plain `trace msg x` would compute `x` before printing `msg`. Building the primes as a lazy `Seq` restores the "trace when the value is used" order:

```ocaml
let any_calculation_will_do' n =
  trace (Printf.sprintf "   -- sieve n: %d" n) (sieve (Seq.ints 2))
  |> Seq.take n
  |> List.of_seq
```

`Seq.take n` forces exactly the first `n` primes, and `List.of_seq` collects them. Run it:

```bash
cd source-code/debugging
dune exec ./trace_timer.exe
```

The trace lines go to stderr and the final list, `[2; 3; 5; 7; 11]`, goes to stdout. Because stderr and stdout are separate, you can keep the debug chatter and still pipe the real output somewhere clean.

## Timing and Timeouts

The file `source-code/timers/timer_test.ml` reuses the same lazy sieve and adds two tools every performance study needs: a benchmark timer and a hard timeout.

The timer wraps a function, prints how long it took, and returns its value:

```ocaml
let time_it label f =
  let t0 = Unix.gettimeofday () in
  let v = f () in
  Printf.printf "%s: %.6f s\n%!" label (Unix.gettimeofday () -. t0);
  v
```

`Unix.gettimeofday` returns wall-clock seconds as a float. Because `time_it` returns `v`, you can wrap any expression in it without changing what the program computes.

The timeout is the interesting part. It runs `f ()` but gives up with `None` if the work runs past a deadline:

```ocaml
exception Timeout

let timeout seconds f =
  let old = Sys.signal Sys.sigalrm (Sys.Signal_handle (fun _ -> raise Timeout)) in
  let disarm () =
    ignore (Unix.setitimer Unix.ITIMER_REAL
              { Unix.it_interval = 0.; it_value = 0. });
    Sys.set_signal Sys.sigalrm old
  in
  ignore (Unix.setitimer Unix.ITIMER_REAL
            { Unix.it_interval = 0.; it_value = seconds });
  match f () with
  | v -> disarm (); Some v
  | exception Timeout -> disarm (); None
```

Here is how it works. `Unix.setitimer` arms an interval timer that fires the `SIGALRM` signal after `seconds`. The signal handler raises the `Timeout` exception. The `match f () with` form catches both a normal result and that exception: a normal value gives `Some v`, and `Timeout` gives `None`. Either way `disarm` cancels the timer and restores the old signal handler, so the timeout leaves no trace behind.

One detail makes this work. OCaml delivers signals at memory allocation points, so a loop that allocates (like the sieve building lists) can be cut off mid-run. A tight loop that never allocates could run past the deadline, but the allocating computations in this book are all interruptible.

The demo prints how long the prime runs take, then tries the sieve under a 0.1 second limit for growing sizes:

```ocaml
List.iter
  (fun n ->
     report_timeout (Printf.sprintf "primes %d" n)
       (timeout 0.1 (fun () -> ignore (last (any_calculation_will_do n)))))
  [ 4; 40; 400; 4000; 40000 ]
```

Small sizes finish in time; the large ones time out and report so. Run it with `dune exec ./timer_test.exe`. You now have three reusable tools: a `State` module, lazy `Seq` streams, and a timeout, each built from a handful of lines of standard OCaml.
