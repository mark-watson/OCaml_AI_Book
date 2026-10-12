(* Build a SPARQL query URL for a public endpoint and decode the standard
   SPARQL 1.1 JSON results format. The Haskell examples used several libraries
   (hsparql, hxt, aeson); this one small module covers the HTTP-JSON case. *)

let dbpedia = "https://dbpedia.org/sparql"

(* Uri.add_query_params' URL-encodes the query text for us, which the Haskell
   code had to do explicitly with urlEncode. *)
let query_uri ?(endpoint = dbpedia) ?(format = "json") sparql =
  Uri.add_query_params'
    (Uri.of_string endpoint)
    [ ("query", sparql); ("format", format) ]

(* Collect the "value" of a named variable across every result binding. *)
let values_of_json var json =
  let open Yojson.Safe.Util in
  json |> member "results" |> member "bindings" |> to_list
  |> List.filter_map (fun binding ->
         match binding |> member var with
         | `Null -> None
         | v -> Some (v |> member "value" |> to_string))
