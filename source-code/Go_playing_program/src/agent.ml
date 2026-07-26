(* A light Go agent: play a legal move, preferring captures, and never fill your
   own eyes (so groups stay alive and self-play terminates). The Haskell program
   had a much larger AI stack (MCTS, joseki, strategic and tactical evaluation);
   this captures the playable core. *)

open Board

let total_captures b = fst b.captures + snd b.captures

let choose_move b =
  let n = b.sz * b.sz in
  let candidates =
    List.filter
      (fun i ->
        b.grid.(i) = 0
        && (not (is_own_eye b i b.to_move))
        && try_play_idx b i <> None)
      (List.init n Fun.id)
  in
  match candidates with
  | [] -> Pass
  | _ ->
    let capturing =
      List.filter
        (fun i ->
          match try_play_idx b i with
          | Some b' -> total_captures b' > total_captures b
          | None -> false)
        candidates
    in
    let pick lst = List.nth lst (Random.int (List.length lst)) in
    let i = match capturing with [] -> pick candidates | _ -> pick capturing in
    Play (row_of b i, col_of b i)
