open Go.Board

let test_empty () =
  let b = empty_board 9 in
  Alcotest.(check int) "size 9" 9 b.sz;
  Alcotest.(check int) "81 cells" 81 (Array.length b.grid);
  Alcotest.(check bool) "all empty" true
    (List.for_all (fun i -> stone_at b i = Empty) (List.init 81 Fun.id))

let test_idx () =
  let b = empty_board 9 in
  Alcotest.(check int) "0,0" 0 (board_idx b 0 0);
  Alcotest.(check int) "0,8" 8 (board_idx b 0 8);
  Alcotest.(check int) "8,0" 72 (board_idx b 8 0);
  Alcotest.(check int) "8,8" 80 (board_idx b 8 8);
  let b13 = empty_board 13 in
  let i = board_idx b13 5 7 in
  Alcotest.(check int) "row" 5 (row_of b13 i);
  Alcotest.(check int) "col" 7 (col_of b13 i)

let test_neighbors () =
  let b = empty_board 9 in
  Alcotest.(check int) "corner" 2 (List.length (neighbors b 0));
  Alcotest.(check int) "edge" 3 (List.length (neighbors b 1));
  Alcotest.(check int) "center" 4 (List.length (neighbors b 40))

let test_opp () =
  Alcotest.(check bool) "black->white" true (opp Black = White);
  Alcotest.(check bool) "white->black" true (opp White = Black)

let test_try_play () =
  let b = empty_board 9 in
  (match try_play b 4 4 with
   | None -> Alcotest.fail "expected legal move"
   | Some b' ->
     Alcotest.(check bool) "black stone placed" true
       (stone_at b' (board_idx b' 4 4) = Occupied Black);
     Alcotest.(check bool) "white to move" true (b'.to_move = White));
  match try_play_idx b 40 with
  | Some b' -> Alcotest.(check bool) "occupied is illegal" true (try_play_idx b' 40 = None)
  | None -> Alcotest.fail "first move should succeed"

let test_pass () =
  let b = empty_board 9 in
  Alcotest.(check bool) "turn flips" true ((pass_move b).to_move = White);
  Alcotest.(check bool) "grid unchanged" true ((pass_move b).grid = b.grid)

let test_capture () =
  (* Black surrounds a white stone and captures it. *)
  let b = empty_board 9 in
  let play bd r c = match try_play bd r c with Some b' -> b' | None -> Alcotest.failf "illegal %d,%d" r c in
  let b = play b 0 1 in   (* B *)
  let b = play b 0 0 in   (* W corner, liberties: (0,1)B and (1,0) *)
  let b = play b 8 8 in   (* B elsewhere *)
  let b = play b 5 5 in   (* W elsewhere *)
  let b = play b 1 0 in   (* B fills last liberty -> captures W at 0,0 *)
  Alcotest.(check bool) "white corner captured" true (stone_at b 0 = Empty);
  Alcotest.(check int) "black captured one" 1 (fst b.captures)

let test_area_score () =
  let b = empty_board 9 in
  Alcotest.(check bool) "empty near 0" true (Float.abs (area_score b) < 1.0)

let () =
  Alcotest.run "Go"
    [ ( "board",
        [ Alcotest.test_case "empty" `Quick test_empty;
          Alcotest.test_case "idx" `Quick test_idx;
          Alcotest.test_case "neighbors" `Quick test_neighbors;
          Alcotest.test_case "opp" `Quick test_opp;
          Alcotest.test_case "try_play" `Quick test_try_play;
          Alcotest.test_case "pass" `Quick test_pass;
          Alcotest.test_case "capture" `Quick test_capture;
          Alcotest.test_case "area_score" `Quick test_area_score ] ) ]
