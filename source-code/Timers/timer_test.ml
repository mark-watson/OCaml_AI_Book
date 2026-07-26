(* Timing and timeout utilities.

   Haskell used Data.Time.Clock.POSIX (getPOSIXTime), System.TimeIt (timeIt),
   and System.Timeout (timeout). OCaml's stdlib plus Unix cover all three:
   - wall-clock time from Unix.gettimeofday
   - a small time_it helper for benchmarking
   - a timeout built on a SIGALRM interval timer *)

exception Timeout

(* Run [f ()] but abort with None if it takes longer than [seconds].
   SIGALRM is delivered at allocation points, so an allocating loop (like the
   sieve below building lists) can be interrupted. *)
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

let time_it label f =
  let t0 = Unix.gettimeofday () in
  let v = f () in
  Printf.printf "%s: %.6f s\n%!" label (Unix.gettimeofday () -. t0);
  v

(* First n primes using a lazy sieve. *)
let rec sieve seq () =
  match seq () with
  | Seq.Nil -> Seq.Nil
  | Seq.Cons (p, rest) ->
    Seq.Cons (p, sieve (Seq.filter (fun y -> y mod p <> 0) rest))

let any_calculation_will_do n =
  sieve (Seq.ints 2) |> Seq.take n |> List.of_seq

let last = function
  | [] -> invalid_arg "last: empty list"
  | xs -> List.nth xs (List.length xs - 1)

let report_timeout name = function
  | None -> Printf.printf "%s: calculation timed out!\n" name
  | Some _ -> Printf.printf "%s: calculation finished in time.\n" name

let () =
  let start = Unix.gettimeofday () in
  Printf.printf "start: %f\n" start;
  (* Force a non-trivial computation the way the Haskell version does. *)
  let big = Seq.ints 0 |> Seq.take 20_000_001 |> Seq.fold_left (fun _ x -> x) 0 in
  Printf.printf "last of 0..20000000 = %d\n" big;
  let stop = Unix.gettimeofday () in
  Printf.printf "stop: %f\nelapsed: %f\n" stop (stop -. start);

  time_it "primes 2000"
    (fun () -> Printf.printf "%d\n" (last (any_calculation_will_do 2000)));
  time_it "primes 3333"
    (fun () -> Printf.printf "%d\n" (last (any_calculation_will_do 3333)));

  (* 0.1 second timeout tests. *)
  report_timeout "print"
    (timeout 0.1 (fun () -> print_endline "simple print statement did not timeout"));
  List.iter
    (fun n ->
       report_timeout (Printf.sprintf "primes %d" n)
         (timeout 0.1 (fun () -> ignore (last (any_calculation_will_do n)))))
    [ 4; 40; 400; 4000; 40000 ];

  let primes = any_calculation_will_do 5 in
  Printf.printf "[%s]\n" (String.concat "; " (List.map string_of_int primes))
