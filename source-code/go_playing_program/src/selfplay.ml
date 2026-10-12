(* One self-play game with the light agent, from an empty board to two passes
   in a row or a move cap. Moved out of bin/main.ml so the single-game driver
   and the parallel playout driver share it. *)

open Board

type result = Black_wins | White_wins | Draw

let play_game ?(sz = 9) () =
  let b = ref (empty_board sz) in
  let passes = ref 0 and moves = ref 0 in
  let max_moves = 3 * sz * sz in
  while !passes < 2 && !moves < max_moves do
    (match Agent.choose_move !b with
     | Pass ->
       incr passes;
       b := pass_move !b
     | Play (r, c) -> (
       match try_play !b r c with
       | Some nb ->
         passes := 0;
         b := nb
       | None ->
         incr passes;
         b := pass_move !b));
    incr moves
  done;
  (!b, !moves)

let result_of b =
  let s = area_score b in
  if s > 0. then Black_wins else if s < 0. then White_wins else Draw
