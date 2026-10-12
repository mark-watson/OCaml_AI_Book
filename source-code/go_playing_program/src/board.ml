(* Board: the core Go engine, ported from the Haskell Board module. It handles
   captures, suicide, ko, legal moves, area scoring, and eye detection. The grid
   is a flat int array (0 = empty, 1 = black, 2 = white); boards are persistent
   (writes copy the array). *)

module ISet = Set.Make (Int)

type color = Black | White
type stone = Empty | Occupied of color
type move = Play of int * int | Pass

type board = {
  grid : int array; (* row-major; 0 empty, 1 black, 2 white *)
  sz : int;
  to_move : color;
  prev_hash : int; (* hash of the position before the last move, for ko *)
  last_move : int option;
  captures : int * int; (* (black's captures, white's captures) *)
}

let opp = function Black -> White | White -> Black
let color_to_int = function Black -> 1 | White -> 2
let int_to_stone = function 1 -> Occupied Black | 2 -> Occupied White | _ -> Empty

let empty_board sz =
  {
    grid = Array.make (sz * sz) 0;
    sz;
    to_move = Black;
    prev_hash = 0;
    last_move = None;
    captures = (0, 0);
  }

let clone_board b = b (* persistent already *)
let board_size b = b.sz
let board_idx b r c = (r * b.sz) + c
let row_of b i = i / b.sz
let col_of b i = i mod b.sz
let stone_at b i = int_to_stone b.grid.(i)
let at_rc b r c = stone_at b (board_idx b r c)
let grid_list b = Array.to_list b.grid

let neighbors_raw sz i =
  let r = i / sz and c = i mod sz in
  (if r > 0 then [ i - sz ] else [])
  @ (if r < sz - 1 then [ i + sz ] else [])
  @ (if c > 0 then [ i - 1 ] else [])
  @ if c < sz - 1 then [ i + 1 ] else []

let neighbors b i = neighbors_raw b.sz i

(* Flood-fill the connected group of [color] starting at [seed]. *)
let flood_group grid sz color seed =
  let rec go stack seen acc =
    match stack with
    | [] -> acc
    | x :: xs ->
      if ISet.mem x seen then go xs seen acc
      else if grid.(x) <> color then go xs seen acc
      else go (neighbors_raw sz x @ xs) (ISet.add x seen) (x :: acc)
  in
  go [ seed ] ISet.empty []

let count_libs_of grid sz stones =
  List.fold_left
    (fun libs s ->
      List.fold_left
        (fun ls nb -> if grid.(nb) = 0 then ISet.add nb ls else ls)
        libs (neighbors_raw sz s))
    ISet.empty stones
  |> ISet.cardinal

type group_info = { stones : int list; liberties : int }

let group_info b seed =
  if b.grid.(seed) = 0 then { stones = []; liberties = 0 }
  else
    let color = b.grid.(seed) in
    let stones = flood_group b.grid b.sz color seed in
    { stones; liberties = count_libs_of b.grid b.sz stones }

let liberty_count b i = (group_info b i).liberties

let hash_grid grid =
  Array.fold_left (fun h v -> ((h * 33) lxor v) land 0xFFFFFFFF) 5381 grid

(* Remove enemy groups with no liberties that touch the given indices. *)
let remove_dead_groups grid0 sz enemy indices =
  let grid = Array.copy grid0 in
  let removed = ref 0 in
  List.iter
    (fun nb ->
      if grid.(nb) = enemy then begin
        let grp = flood_group grid sz enemy nb in
        if count_libs_of grid sz grp = 0 then begin
          List.iter (fun idx -> grid.(idx) <- 0) grp;
          removed := !removed + List.length grp
        end
      end)
    indices;
  (grid, !removed)

(* Try to play at flat index [i]. Returns None if illegal. *)
let try_play_idx b i =
  if b.grid.(i) <> 0 then None
  else begin
    let color = color_to_int b.to_move in
    let enemy = color_to_int (opp b.to_move) in
    let sz = b.sz in
    let trial0 = Array.copy b.grid in
    trial0.(i) <- color;
    let trial1, removed = remove_dead_groups trial0 sz enemy (neighbors_raw sz i) in
    let own_libs = count_libs_of trial1 sz (flood_group trial1 sz color i) in
    if own_libs = 0 then None (* suicide *)
    else
      let new_hash = hash_grid trial1 in
      if b.prev_hash <> 0 && new_hash = b.prev_hash then None (* ko *)
      else
        let bc, wc = b.captures in
        let captures' =
          match b.to_move with
          | Black -> (bc + removed, wc)
          | White -> (bc, wc + removed)
        in
        Some
          {
            grid = trial1; sz;
            to_move = opp b.to_move;
            prev_hash = hash_grid b.grid;
            last_move = Some i;
            captures = captures';
          }
  end

let try_play b r c = try_play_idx b (board_idx b r c)

let pass_move b =
  { b with to_move = opp b.to_move; last_move = None; prev_hash = 0 }

let legal_moves b =
  List.filter (fun i -> b.grid.(i) = 0) (List.init (Array.length b.grid) Fun.id)

let compute_territory b =
  let n = b.sz * b.sz in
  let visited = Array.make n false in
  let bt = ref 0 and wt = ref 0 in
  for i = 0 to n - 1 do
    if b.grid.(i) = 0 && not visited.(i) then begin
      let region = ref 0 and touch_b = ref false and touch_w = ref false in
      let rec flood stack =
        match stack with
        | [] -> ()
        | x :: xs ->
          if visited.(x) then flood xs
          else begin
            visited.(x) <- true;
            incr region;
            let more =
              List.filter_map
                (fun nb ->
                  match b.grid.(nb) with
                  | 0 -> if visited.(nb) then None else Some nb
                  | 1 -> touch_b := true; None
                  | _ -> touch_w := true; None)
                (neighbors_raw b.sz x)
            in
            flood (more @ xs)
          end
      in
      flood [ i ];
      if !touch_b && not !touch_w then bt := !bt + !region
      else if !touch_w && not !touch_b then wt := !wt + !region
    end
  done;
  (!bt, !wt)

(* Chinese-style area score from Black's perspective. *)
let area_score b =
  let bs = ref 0 and ws = ref 0 in
  Array.iter (fun v -> if v = 1 then incr bs else if v = 2 then incr ws) b.grid;
  let bt, wt = compute_territory b in
  float_of_int (!bs + bt) -. float_of_int (!ws + wt)

let is_own_eye b i color =
  let sz = b.sz in
  let col_i = color_to_int color in
  let r = i / sz and c = i mod sz in
  let all_friendly = List.for_all (fun nb -> b.grid.(nb) = col_i) (neighbors_raw sz i) in
  let diags =
    List.concat_map
      (fun dr ->
        List.filter_map
          (fun dc ->
            let nr = r + dr and nc = c + dc in
            if nr >= 0 && nr < sz && nc >= 0 && nc < sz then Some ((nr * sz) + nc)
            else None)
          [ -1; 1 ])
      [ -1; 1 ]
  in
  let diag_count = List.length diags in
  let diag_friends = List.length (List.filter (fun d -> b.grid.(d) = col_i) diags) in
  all_friendly
  && if diag_count < 4 then diag_friends = diag_count else diag_friends >= 3
