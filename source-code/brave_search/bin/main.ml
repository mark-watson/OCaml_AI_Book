(* Query the Brave Search API and print the results. Set BRAVE_SEARCH_API_KEY
   and pass a search query as the first argument. *)

open Lwt.Syntax

let endpoint = "https://api.search.brave.com/res/v1/web/search"

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

let () =
  let query =
    match Array.to_list Sys.argv with _ :: q :: _ -> q | _ -> "OCaml programming"
  in
  match Sys.getenv_opt "BRAVE_SEARCH_API_KEY" with
  | None ->
    print_endline "Error: BRAVE_SEARCH_API_KEY environment variable not set.";
    exit 1
  | Some api_key -> (
    match Lwt_main.run (get_search_suggestions ~api_key query) with
    | Ok lines -> List.iter print_endline lines
    | Error e ->
      Printf.eprintf "%s\n" e;
      exit 1)
