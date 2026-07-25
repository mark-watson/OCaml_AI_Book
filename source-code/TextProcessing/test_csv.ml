(* Read and print a CSV file using the csv library (the OCaml analogue of
   Haskell's Text.CSV). *)

let read_csv_file fname =
  try Csv.load fname
  with e ->
    Printf.printf "CSV parse error: %s\n" (Printexc.to_string e);
    []

let show_row r =
  "[" ^ String.concat "," (List.map (Printf.sprintf "%S") r) ^ "]"

let show_csv c = "[" ^ String.concat "," (List.map show_row c) ^ "]"

let () =
  let c = read_csv_file "test.csv" in
  print_endline (show_csv c);
  (* first column of every row (Haskell: map head c) *)
  print_endline (show_row (List.map List.hd c));
  match c with
  | [] -> print_endline "Warning: CSV file is empty, no header or rows."
  | header :: rows ->
      print_endline (show_row header);
      print_endline (show_csv rows)
