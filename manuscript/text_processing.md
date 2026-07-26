# Text Processing and DataFrames

Most data work starts with cleaning text and reading tables. This chapter covers both. First it cleans free text and reads CSV and JSON, from `source-code/TextProcessing/`. Then it builds a small dataframe and runs a real analysis over a housing dataset, from `source-code/dataframe_example/`.

## Cleaning Free Text

The file `TextProcessing/clean_text.ml` prepares raw text for later processing. It does three things: it pushes spaces around punctuation so words and marks separate cleanly, it drops noise characters, and it removes common stop words.

The noise characters are a plain list, and `substitute_noise_characters` turns each one into a space:

```ocaml
let noise_characters =
  [ '['; ']'; '{'; '}'; '\n'; '\t'; '&'; '^'; '@'; '%'; '$'; '#' ]

let substitute_noise_characters s =
  String.map (fun c -> if List.mem c noise_characters then ' ' else c) s
```

`String.map` applies a function to every character and returns a new string. `List.mem` tests membership. The standard library has no `String.replace`, so the file supplies one built on a `Buffer`, which grows a string efficiently without rebuilding it each time:

```ocaml
let replace_str old_s new_s s =
  let ol = String.length old_s in
  if ol = 0 then s
  else begin
    let buf = Buffer.create (String.length s) in
    let n = String.length s in
    let i = ref 0 in
    while !i < n do
      if !i + ol <= n && String.sub s !i ol = old_s then begin
        Buffer.add_string buf new_s;
        i := !i + ol
      end
      else begin
        Buffer.add_char buf s.[!i];
        incr i
      end
    done;
    Buffer.contents buf
  end
```

This is imperative OCaml: a `ref` cell for the index, a `while` loop, and a `Buffer` that collects the result. When the text at the cursor matches `old_s`, it appends the replacement and jumps ahead; otherwise it copies one character. `cleanText` chains everything with the pipe operator:

```ocaml
let clean_text s =
  s
  |> replace_str ";" " ; "
  |> replace_str "," " , "
  |> replace_str "." " . "
  |> substitute_noise_characters
  |> String.split_on_char ' '
  |> List.filter (fun x -> String.length x > 0)
  |> String.concat " "
```

Read top to bottom: space out the semicolons, commas, and periods, turn noise into spaces, split on spaces, drop the empty pieces, and join back with single spaces. The result has clean, single-spaced tokens. Removing stop words is one more filter:

```ocaml
let stop_words = [ "a"; "the"; "that"; "of"; "an"; "and" ]

let remove_stop_words s =
  String.split_on_char ' ' s
  |> List.filter (fun x -> x <> "")
  |> List.filter (fun x -> not (List.mem (String.lowercase_ascii x) stop_words))
  |> String.concat " "
```

It splits into words and keeps only the ones that are not stop words, comparing in lower case so `The` and `the` both go.

## Reading CSV

The `csv` library reads a comma-separated file into a list of rows, where each row is a list of string cells. The file `TextProcessing/test_csv.ml` loads a file and prints it, guarding against a parse error:

```ocaml
let read_csv_file fname =
  try Csv.load fname
  with e ->
    Printf.printf "CSV parse error: %s\n" (Printexc.to_string e);
    []
```

`Csv.load` returns `string list list`. Once you have that, ordinary list functions do the rest. The demo pulls the first column of every row with `List.map List.hd`, and splits the header from the body by matching the list:

```ocaml
match c with
| [] -> print_endline "Warning: CSV file is empty, no header or rows."
| header :: rows ->
    print_endline (show_row header);
    print_endline (show_csv rows)
```

## Round-Tripping JSON

For JSON the book uses [Yojson](https://github.com/ocaml-community/yojson) everywhere. A JSON value is a polymorphic variant: `` `Assoc `` for an object, `` `String `` for text, and so on. The file `TextProcessing/test_json.ml` encodes a record to JSON and reads it back:

```ocaml
type person = { name : string; email : string }

let person_to_json p =
  `Assoc [ ("name", `String p.name); ("email", `String p.email) ]

let person_of_json j =
  let open Yojson.Safe.Util in
  { name = j |> member "name" |> to_string; email = j |> member "email" |> to_string }
```

To build JSON, you construct the variant directly: an `` `Assoc `` is a list of key-value pairs. To read it, the `Yojson.Safe.Util` module gives you accessors: `member "name"` pulls a field out of an object, and `to_string` reads it as a string. The `j |> member "name" |> to_string` pipeline reads left to right. Decoding is wrapped in a `try` so malformed input gives a clear message instead of an exception. This small encoder-decoder pattern is the same one the LLM and search chapters use for real API payloads.

## A Small DataFrame

A dataframe is a table you can filter, sort, and aggregate by column name. The file `dataframe_example/src/dataframe.ml` builds one over the `csv` library. It stores every cell as a string and parses numbers on demand, which keeps the type simple:

```ocaml
type t = { columns : string array; rows : string array array }

let num s = Option.value ~default:0. (float_of_string_opt (String.trim s))

let index t name =
  let rec go i =
    if i >= Array.length t.columns then invalid_arg ("no such column: " ^ name)
    else if t.columns.(i) = name then i
    else go (i + 1)
  in
  go 0
```

A dataframe is a header array plus a two-dimensional array of string cells. `num` reads a cell as a float, defaulting to zero on junk. `index` finds a column's position by name, which every other operation uses to reach a cell.

Loading and saving wrap `Csv.load` and `Csv.save`. The interesting operations are the transforms. `derive` adds a computed column. It hands your function an accessor `g` that reads any column of the current row as a float:

```ocaml
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
```

So `derive d "rooms_per_household" (fun g -> g "total_rooms" /. g "households")` appends a new column computed from two existing ones. Filtering keeps the rows that pass a test, with one version for numeric columns and one for string columns:

```ocaml
let filter_float t name pred =
  let i = index t name in
  { t with rows = Array.of_list (List.filter (fun r -> pred (num r.(i)))
                                   (Array.to_list t.rows)) }
```

`select` narrows to a set of columns, and `sort_by_float` sorts on a numeric column, ascending or descending, with `Array.stable_sort` so equal rows keep their order. The aggregation step groups rows by a key column and computes one or more aggregates per group:

```ocaml
type agg = Count | Mean of string

let group_by t ~key ~aggs =
  let ki = index t key in
  ...
  let compute rows = function
    | Count -> float_of_int (List.length rows)
    | Mean src ->
      let i = index t src in
      let xs = List.map (fun r -> num r.(i)) rows in
      (match xs with
       | [] -> 0.
       | _ -> List.fold_left ( +. ) 0. xs /. float_of_int (List.length xs))
  in
  ...
```

An aggregate is a small variant: `Count`, or `Mean` of a named column. The function collects the unique keys in first-seen order (using a `Hashtbl` to remember which it has seen), then for each key computes every requested aggregate. There is also `summarize`, which reports count, mean, min, and max for every numeric column, and `print`, which lays the table out with aligned columns.

## The Housing Analysis

The driver `dataframe_example/bin/main.ml` runs a full analysis over a California housing sample. It reads the CSV, prints summary statistics, and derives three columns:

```ocaml
let enriched =
  df
  |> fun d ->
  D.derive d "rooms_per_household" (fun g -> g "total_rooms" /. g "households")
  |> fun d ->
  D.derive d "population_per_household" (fun g ->
      g "population" /. g "households")
  |> fun d ->
  D.derive d "bedrooms_per_room" (fun g ->
      g "total_bedrooms" /. g "total_rooms")
in
```

It then filters for expensive coastal properties, sorts to find the most expensive, and groups by ocean proximity to compare average value and income across regions:

```ocaml
let by_proximity =
  D.group_by enriched ~key:"ocean_proximity"
    ~aggs:
      [ ("num_districts", D.Count);
        ("avg_house_value", D.Mean "median_house_value");
        ("avg_income", D.Mean "median_income");
        ("avg_rooms_per_hh", D.Mean "rooms_per_household") ]
  |> fun d -> D.sort_by_float ~desc:true d "avg_house_value"
```

Finally it writes the enriched table back to a new CSV. The labelled arguments `~key` and `~aggs` make the call read almost like a sentence: group by ocean proximity, aggregating these four measures.

## Running It

Run from the project root so the data file resolves:

```bash
cd source-code/dataframe_example
dune build
dune exec ./bin/main.exe
dune runtest
```

The program prints the first rows, the summary statistics, the derived columns, the expensive coastal listings, the top five by price, and the per-region averages, then writes `./data/housing_enriched.csv`. In under 200 lines you have a working dataframe with derive, filter, select, sort, group, and aggregate, built from arrays, `Hashtbl`, and the `csv` library.
