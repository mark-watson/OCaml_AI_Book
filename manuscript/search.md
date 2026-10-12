# Search APIs: Brave Search

Giving a program web search turns it from a closed system into one that can look things up. This chapter builds a client for the [Brave Search API](https://brave.com/search/api/), in `source-code/brave_search/`. It sends a query and prints the original query plus one line per result. The structure is the one from the last chapter: a pure codec you can test offline, and a thin Lwt wrapper for the HTTP call.

## Modeling a Result

A search result has many fields, and any of them can be missing from a given response. That is a job for the `option` type. The file `lib/brave.ml` models one web result as a record where the optional fields have `option` types:

```ocaml
type web_result = {
  type_ : string;
  index : int option;
  all : bool option;
  title : string option;
  url : string option;
  description : string option;
}
```

Only `type_` is always present; the rest are `option`, so a result with no description holds `None` there rather than an empty string or a crash. The field is named `type_` because `type` is a reserved word in OCaml.

## Decoding Optional Fields

Decoding these fields needs a small helper, because each one might be JSON `null`. The `opt` function takes a converter and returns `None` for `null` or `Some value` otherwise:

```ocaml
let opt conv = function `Null -> None | v -> Some (conv v)
```

With `opt` in hand, decoding a whole result reads cleanly. Each line pipes the field through `opt` and the right converter:

```ocaml
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
```

`opt to_string` reads a string or gives `None`; `opt to_int` and `opt to_bool` do the same for numbers and booleans. This little combinator replaces the special optional-field accessor a JSON library might give you, and it works for any type.

## Formatting a Result

Turning a result into a readable line means handling the missing fields. `format_result` prints each field or `N/A`, and trims a long description to 100 characters:

```ocaml
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
```

The local `field` helper takes a label and an `option`, and returns the labeled value or `N/A`. Decoding a whole response gives the query line followed by one formatted line per result:

```ocaml
let suggestions_of_json json =
  let open Yojson.Safe.Util in
  let original = json |> member "query" |> member "original" |> to_string in
  let results =
    json |> member "web" |> member "results" |> to_list
    |> List.map web_result_of_json
  in
  ("Original Query: " ^ original) :: List.map format_result results
```

## The HTTP Call

The program in `bin/main.ml` sends the query. Brave takes the search terms as URL query parameters and the API key as a header. `Uri.add_query_params'` builds the URL and encodes the terms:

```ocaml
let get_search_suggestions ~api_key query =
  let uri =
    Uri.add_query_params'
      (Uri.of_string endpoint)
      [ ("q", query); ("country", "US"); ("count", "5") ]
  in
  let headers =
    Cohttp.Header.of_list
      [ ("Accept", "application/json"); ("X-Subscription-Token", api_key) ]
  in
  Lwt.catch
    (fun () ->
      let* resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
      let* body_str = Cohttp_lwt.Body.to_string body in
      let code = Cohttp.Code.code_of_status (Cohttp.Response.status resp) in
      if code <> 200 then Lwt.return (Error (Printf.sprintf "HTTP error: %d" code))
      else
        match Yojson.Safe.from_string body_str with
        | json -> Lwt.return (Ok (Brave.suggestions_of_json json))
        | exception e ->
          Lwt.return (Error ("JSON parsing error: " ^ Printexc.to_string e)))
    (fun exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn)))
```

The key goes in the `X-Subscription-Token` header. The call handles three kinds of failure, each as a distinct `Error`: a non-200 status, a JSON parse error (caught with the `exception e` case in the `match`), and a network exception (caught by `Lwt.catch`). The main function reads the query from the command line and the key from the environment:

```ocaml
let () =
  let query =
    match Array.to_list Sys.argv with _ :: q :: _ -> q | _ -> "OCaml programming"
  in
  match Sys.getenv_opt "BRAVE_SEARCH_API_KEY" with
  | None ->
    print_endline "Error: BRAVE_SEARCH_API_KEY environment variable not set.";
    exit 1
  | Some api_key -> ( ... )
```

## Running It

Set your API token and run a search:

```bash
cd source-code/brave_search
export BRAVE_SEARCH_API_KEY=your-token
dune build
dune exec ./bin/main.exe -- "OCaml programming"
dune runtest
```

The program prints the original query and up to five results, one per line. Because the decode lives in `brave.ml` and takes a parsed JSON value, the tests decode a saved sample response offline, so `dune runtest` needs no token and no network. The `opt` combinator you saw here is worth keeping: whenever you decode JSON with fields that may be absent, one small `opt conv` function handles them all.
