(* A small string-cell dataframe, enough to reproduce the housing analysis from
   the Haskell `dataframe` library example: load a CSV, derive columns, filter,
   select, sort, group and aggregate, and write a CSV. Numbers are parsed on
   demand. Built on the `csv` library plus the standard library. *)

type t = { columns : string array; rows : string array array }

let fmt f = Printf.sprintf "%g" f
let num s = Option.value ~default:0. (float_of_string_opt (String.trim s))

let index t name =
  let rec go i =
    if i >= Array.length t.columns then invalid_arg ("no such column: " ^ name)
    else if t.columns.(i) = name then i
    else go (i + 1)
  in
  go 0

let make ~columns ~rows =
  { columns = Array.of_list columns;
    rows = Array.of_list (List.map Array.of_list rows) }

let read_csv path =
  match Csv.load path with
  | [] -> { columns = [||]; rows = [||] }
  | header :: data ->
    { columns = Array.of_list header;
      rows = Array.of_list (List.map Array.of_list data) }

let write_csv path t =
  let header = Array.to_list t.columns in
  let rows = Array.to_list (Array.map Array.to_list t.rows) in
  Csv.save path (header :: rows)

let n_rows t = Array.length t.rows
let take n t = { t with rows = Array.sub t.rows 0 (min n (Array.length t.rows)) }

(* Add a column computed from the numeric value of existing columns. The
   function is given an accessor `g` that reads a column of the current row as a
   float, mirroring `F.col @Int "total_rooms"` in the Haskell version. *)
let derive t name f =
  let cols = Array.append t.columns [| name |] in
  let rows =
    Array.map
      (fun row ->
        let g col = num row.(index t col) in
        Array.append row [| fmt (f g) |])
      t.rows
  in
  { columns = cols; rows }

let filter_float t name pred =
  let i = index t name in
  { t with rows = Array.of_list (List.filter (fun r -> pred (num r.(i)))
                                   (Array.to_list t.rows)) }

let filter_string t name pred =
  let i = index t name in
  { t with rows = Array.of_list (List.filter (fun r -> pred r.(i))
                                   (Array.to_list t.rows)) }

let select t names =
  let idxs = List.map (index t) names in
  {
    columns = Array.of_list names;
    rows =
      Array.map
        (fun r -> Array.of_list (List.map (fun i -> r.(i)) idxs))
        t.rows;
  }

let sort_by_float ?(desc = false) t name =
  let i = index t name in
  let cmp a b =
    let c = compare (num a.(i)) (num b.(i)) in
    if desc then -c else c
  in
  let rows = Array.copy t.rows in
  Array.stable_sort cmp rows;
  { t with rows }

type agg = Count | Mean of string

let group_by t ~key ~aggs =
  let ki = index t key in
  let seen = Hashtbl.create 16 in
  let keys =
    Array.fold_left
      (fun acc r ->
        let k = r.(ki) in
        if Hashtbl.mem seen k then acc
        else (Hashtbl.add seen k (); k :: acc))
      [] t.rows
    |> List.rev
  in
  let rows_for k = List.filter (fun r -> r.(ki) = k) (Array.to_list t.rows) in
  let compute rows = function
    | Count -> float_of_int (List.length rows)
    | Mean src ->
      let i = index t src in
      let xs = List.map (fun r -> num r.(i)) rows in
      (match xs with
       | [] -> 0.
       | _ -> List.fold_left ( +. ) 0. xs /. float_of_int (List.length xs))
  in
  let columns = Array.of_list (key :: List.map fst aggs) in
  let rows =
    List.map
      (fun k ->
        let rs = rows_for k in
        Array.of_list (k :: List.map (fun (_, a) -> fmt (compute rs a)) aggs))
      keys
  in
  { columns; rows = Array.of_list rows }

(* Per-numeric-column count, mean, min, and max, returned as a dataframe. *)
let summarize t =
  let is_num name =
    n_rows t > 0
    && float_of_string_opt (String.trim t.rows.(0).(index t name)) <> None
  in
  let numeric = List.filter is_num (Array.to_list t.columns) in
  let stats name =
    let i = index t name in
    let xs = Array.to_list (Array.map (fun r -> num r.(i)) t.rows) in
    let n = List.length xs in
    let mean = List.fold_left ( +. ) 0. xs /. float_of_int (max 1 n) in
    let mn = List.fold_left min infinity xs in
    let mx = List.fold_left max neg_infinity xs in
    [ name; string_of_int n; fmt mean; fmt mn; fmt mx ]
  in
  make
    ~columns:[ "column"; "count"; "mean"; "min"; "max" ]
    ~rows:(List.map stats numeric)

let print ?(max_rows = max_int) t =
  let widths = Array.map String.length t.columns in
  let shown = min max_rows (Array.length t.rows) in
  for r = 0 to shown - 1 do
    Array.iteri
      (fun c cell -> widths.(c) <- max widths.(c) (String.length cell))
      t.rows.(r)
  done;
  let pad s w = s ^ String.make (max 0 (w - String.length s)) ' ' in
  let line cells =
    print_endline
      (String.concat " | " (Array.to_list (Array.mapi (fun c s -> pad s widths.(c)) cells)))
  in
  line t.columns;
  for r = 0 to shown - 1 do
    line t.rows.(r)
  done
