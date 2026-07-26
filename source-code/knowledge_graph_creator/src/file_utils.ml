(* File helpers: read text, parse the JSON `.meta` files, and load the entity
   corpora. Ported from the Haskell FileUtils module (the meta parser uses
   Yojson instead of Text.JSON.Generic). *)

let read_file path =
  let ic = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () -> really_input_string ic (in_channel_length ic))

let file_to_string path = read_file path
let file_to_word_tokens path = Nlp_utils.split_words_keep_case (read_file path)

type my_meta = { uri : string; similar_docs : string list }

let read_meta_file path =
  let json = Yojson.Safe.from_string (read_file path) in
  let open Yojson.Safe.Util in
  {
    uri = json |> member "uri" |> to_string;
    similar_docs =
      (match json |> member "similar_docs" with
       | `List xs -> List.filter_map (function `String s -> Some s | _ -> None) xs
       | _ -> []);
  }

let is_text_file name = Filename.check_suffix name ".txt"
let is_meta_file name = Filename.check_suffix name ".meta"

type entity_maps = {
  people : (string, string) Hashtbl.t;
  companies : (string, string) Hashtbl.t;
  countries : (string, string) Hashtbl.t;
  cities : (string, string) Hashtbl.t;
  broadcast_networks : (string, string) Hashtbl.t;
  political_parties : (string, string) Hashtbl.t;
  trade_unions : (string, string) Hashtbl.t;
  universities : (string, string) Hashtbl.t;
}

let load_entity_maps data_dir =
  let load f = Nlp_data.load_entity_map (Filename.concat data_dir f) in
  {
    people = load "people.tsv";
    companies = load "companies.tsv";
    countries = load "countries.tsv";
    cities = load "cities.tsv";
    broadcast_networks = load "broadcast_networks.tsv";
    political_parties = load "political_parties.tsv";
    trade_unions = load "trade_unions.tsv";
    universities = load "universities.tsv";
  }
