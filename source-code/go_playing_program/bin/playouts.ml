(* Run many independent self-play games ("playouts") and tally the results,
   first on one core and then spread across OCaml 5 domains. Each game builds
   its own boards, so domains share nothing and need no locks. *)

open Go

type tally = { black : int; white : int; draws : int }

let empty = { black = 0; white = 0; draws = 0 }

let add t = function
  | Selfplay.Black_wins -> { t with black = t.black + 1 }
  | Selfplay.White_wins -> { t with white = t.white + 1 }
  | Selfplay.Draw -> { t with draws = t.draws + 1 }

let merge a b =
  { black = a.black + b.black; white = a.white + b.white;
    draws = a.draws + b.draws }

let run_games n =
  let rec loop i t =
    if i = 0 then t
    else
      let final, _ = Selfplay.play_game () in
      loop (i - 1) (add t (Selfplay.result_of final))
  in
  loop n empty

(* Split [n] games over [d] domains: spawn d - 1 workers, let the current
   domain run its own share, then join the workers and merge their tallies. *)
let run_parallel ~domains n =
  let share k = (n / domains) + if k < n mod domains then 1 else 0 in
  let workers =
    List.init (domains - 1) (fun k ->
        Domain.spawn (fun () -> run_games (share (k + 1))))
  in
  let mine = run_games (share 0) in
  List.fold_left (fun t w -> merge t (Domain.join w)) mine workers

let timed f =
  let t0 = Unix.gettimeofday () in
  let r = f () in
  (r, Unix.gettimeofday () -. t0)

let report label t secs =
  Printf.printf "%-22s Black %3d  White %3d  Draw %2d   %.2fs\n" label t.black
    t.white t.draws secs

let () =
  let games =
    match Sys.argv with
    | [| _; n |] -> int_of_string n
    | _ -> 200
  in
  let domains = Domain.recommended_domain_count () in
  Printf.printf "%d playouts on 9x9, %d domains available\n" games domains;
  let seq, t_seq = timed (fun () -> run_games games) in
  report "sequential" seq t_seq;
  let par, t_par = timed (fun () -> run_parallel ~domains games) in
  report (Printf.sprintf "parallel (%d domains)" domains) par t_par;
  Printf.printf "speedup: %.1fx\n" (t_seq /. t_par)
