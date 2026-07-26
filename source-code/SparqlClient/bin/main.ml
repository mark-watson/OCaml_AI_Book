(* Ask DBpedia for the English-language abstract of IBM and print it. *)

open Lwt.Syntax

let ibm_abstract_query =
  "select ?o where { <http://dbpedia.org/resource/IBM> \
   <http://dbpedia.org/ontology/abstract> ?o . \
   FILTER langMatches(lang(?o), \"EN\") } LIMIT 1"

let run query var =
  let uri = Sparql.query_uri query in
  let headers = Cohttp.Header.of_list [ ("Accept", "application/sparql-results+json") ] in
  Lwt.catch
    (fun () ->
      let* resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
      let* body_str = Cohttp_lwt.Body.to_string body in
      let code = Cohttp.Code.code_of_status (Cohttp.Response.status resp) in
      if code <> 200 then Lwt.return (Error (Printf.sprintf "HTTP error: %d" code))
      else Lwt.return (Ok (Sparql.values_of_json var (Yojson.Safe.from_string body_str))))
    (fun exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn)))

let () =
  print_endline "\nAbstracts:\n";
  match Lwt_main.run (run ibm_abstract_query "o") with
  | Ok [] -> print_endline "(no results - check the SPARQL endpoint or query)"
  | Ok values -> List.iter print_endline values
  | Error e ->
    Printf.eprintf "%s\n" e;
    exit 1
