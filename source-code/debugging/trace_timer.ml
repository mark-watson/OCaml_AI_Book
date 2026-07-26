(* Debug tracing. Haskell has Debug.Trace; OCaml has no built-in trace, so we
   write a tiny helper that prints to stderr and returns its value unchanged.

   OCaml is strict, so a plain [trace msg x] would evaluate [x] before printing.
   To keep Haskell's "print when demanded" flavour we build the primes as a lazy
   [Seq.t], so each element is forced (and traced) only when taken. *)

let trace msg x = Printf.eprintf "%s\n%!" msg; x

(* Sieve of Eratosthenes over a lazy stream of integers. *)
let rec sieve seq () =
  match seq () with
  | Seq.Nil -> Seq.Nil
  | Seq.Cons (p, rest) ->
    Printf.eprintf "     -- inside sieve recursion\n%!";
    Seq.Cons (p, sieve (Seq.filter (fun y -> y mod p <> 0) rest))

let any_calculation_will_do' n =
  trace (Printf.sprintf "   -- sieve n: %d" n) (sieve (Seq.ints 2))
  |> Seq.take n
  |> List.of_seq

let any_calculation_will_do n =
  ignore (trace (Printf.sprintf "+++ any_calculation_will_do: %d" n) ());
  any_calculation_will_do' n

let () =
  let primes = any_calculation_will_do 5 in
  Printf.printf "[%s]\n" (String.concat "; " (List.map string_of_int primes))
