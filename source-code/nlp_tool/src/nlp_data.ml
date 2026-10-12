(* Load the TSV corpora produced by convert_data.py. Keeping the data in files
   (rather than embedded in source, as the Haskell version did with huge Map
   literals) keeps the OCaml small and compiles fast. *)

type ngrams = (string * (string, float) Hashtbl.t) list

let read_lines path =
  let ic = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () ->
      let rec go acc =
        match input_line ic with
        | line -> go (line :: acc)
        | exception End_of_file -> List.rev acc
      in
      go [])

let load_entity_map path : (string, string) Hashtbl.t =
  let tbl = Hashtbl.create 1024 in
  List.iter
    (fun line ->
      match String.split_on_char '\t' line with
      | [ name; uri ] -> Hashtbl.replace tbl name uri
      | _ -> ())
    (read_lines path);
  tbl

let load_ngrams path : ngrams =
  let order = ref [] in
  let maps = Hashtbl.create 64 in
  List.iter
    (fun line ->
      match String.split_on_char '\t' line with
      | [ cat; word; score ] ->
        let m =
          match Hashtbl.find_opt maps cat with
          | Some m -> m
          | None ->
            let m = Hashtbl.create 128 in
            Hashtbl.add maps cat m;
            order := cat :: !order;
            m
        in
        Hashtbl.replace m word (float_of_string score)
      | _ -> ())
    (read_lines path);
  List.rev_map (fun cat -> (cat, Hashtbl.find maps cat)) !order
