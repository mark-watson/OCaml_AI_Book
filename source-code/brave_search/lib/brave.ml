(* Types and JSON decoding for the Brave Search API response. The HTTP call
   lives in bin/main.ml; keeping the decode here lets the tests run offline. *)

type web_result = {
  type_ : string;
  index : int option;
  all : bool option;
  title : string option;
  url : string option;
  description : string option;
}

let opt conv = function `Null -> None | v -> Some (conv v)

let web_result_of_json json =
  let open Yojson.Safe.Util in
  {
    type_ = json |> member "type" |> to_string;
    index = json |> member "index" |> opt to_int;
    all = json |> member "all" |> opt to_bool;
    title = json |> member "title" |> opt to_string;
    url = json |> member "url" |> opt to_string;
    description = json |> member "description" |> opt to_string;
  }

(* One readable line per result, matching the Haskell formatResult. *)
let format_result r =
  let field label = function Some v -> label ^ v | None -> "N/A" in
  let title = field "Title: " r.title in
  let url = field "URL: " r.url in
  let desc =
    match r.description with
    | Some d ->
      let d = if String.length d > 100 then String.sub d 0 100 else d in
      "Description: " ^ d
    | None -> "N/A"
  in
  String.concat " | " [ title; url; desc ]

(* Turn a whole search response into the query line plus one line per result. *)
let suggestions_of_json json =
  let open Yojson.Safe.Util in
  let original = json |> member "query" |> member "original" |> to_string in
  let results =
    json |> member "web" |> member "results" |> to_list
    |> List.map web_result_of_json
  in
  ("Original Query: " ^ original) :: List.map format_result results
