(* Self-play a game of Go on a 9x9 board with the light agent, then print the
   final board and the area score. *)

open Go
open Go.Board

let char_of = function 0 -> '.' | 1 -> 'X' | _ -> 'O'

let print_board b =
  for r = 0 to b.sz - 1 do
    for c = 0 to b.sz - 1 do
      print_char (char_of b.grid.(board_idx b r c));
      print_char ' '
    done;
    print_newline ()
  done

let () =
  Random.self_init ();
  let sz = 9 in
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
  let final = !b in
  Printf.printf "Final board after %d moves (X=Black, O=White):\n" !moves;
  print_board final;
  let bc, wc = final.captures in
  Printf.printf "Captures: Black %d, White %d\n" bc wc;
  let s = area_score final in
  Printf.printf "Area score (Black - White): %.1f\n" s;
  Printf.printf "Result: %s\n"
    (if s > 0. then "Black wins" else if s < 0. then "White wins" else "Draw")
