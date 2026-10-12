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
  let final, moves = Selfplay.play_game ~sz:9 () in
  Printf.printf "Final board after %d moves (X=Black, O=White):\n" moves;
  print_board final;
  let bc, wc = final.captures in
  Printf.printf "Captures: Black %d, White %d\n" bc wc;
  let s = area_score final in
  Printf.printf "Area score (Black - White): %.1f\n" s;
  Printf.printf "Result: %s\n"
    (if s > 0. then "Black wins" else if s < 0. then "White wins" else "Draw")
