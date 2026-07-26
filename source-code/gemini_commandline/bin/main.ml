(* Gemini command-line demo. With no argument it extracts places, people, and
   companies from sample text; with an argument it runs a single completion.
   Set GOOGLE_API_KEY before running. *)

open Lwt.Syntax

let endpoint =
  "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"

let completion ~api_key prompt =
  let body = Yojson.Safe.to_string (Gemini.request_json prompt) in
  let headers =
    Cohttp.Header.of_list
      [ ("Content-Type", "application/json"); ("x-goog-api-key", api_key) ]
  in
  Lwt.catch
    (fun () ->
      let* resp, rbody =
        Cohttp_lwt_unix.Client.post ~headers
          ~body:(Cohttp_lwt.Body.of_string body)
          (Uri.of_string endpoint)
      in
      let* rbody_str = Cohttp_lwt.Body.to_string rbody in
      let code = Cohttp.Code.code_of_status (Cohttp.Response.status resp) in
      if code = 200 then
        Lwt.return (Gemini.text_of_json (Yojson.Safe.from_string rbody_str))
      else Lwt.return (Error (Printf.sprintf "API request failed with status %d" code)))
    (fun exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn)))

let extract_entities ~kind ~example ~api_key text =
  let prompt =
    Printf.sprintf
      "Extract only the %s strictly separated by commas from the following \
       text. Do not include any explanation or introduction. Example: %s\n\n\
       Text:\"%s\""
      kind example text
  in
  let* r = completion ~api_key prompt in
  Lwt.return (Result.map Gemini.split_entities r)

let print_entities label = function
  | Ok items -> Printf.printf "Found %s: [%s]\n" label (String.concat "; " items)
  | Error e -> Printf.printf "Error finding %s: %s\n" label e

let run_demo ~api_key =
  let text =
    "Dr. Evelyn Reed from Acme Corporation went to London last week with her \
     colleague Bob Smith. They visited the Tower Bridge and met someone near \
     Paris, Texas."
  in
  Printf.printf "Sample Text: \"%s\"\n\n" text;
  let* places =
    extract_entities ~kind:"place names" ~example:"London,Paris,Tokyo" ~api_key text
  in
  print_entities "Places" places;
  let* people =
    extract_entities ~kind:"person names" ~example:"Alice,Bob,Charlie" ~api_key text
  in
  print_entities "People" people;
  let* companies =
    extract_entities ~kind:"company names" ~example:"Google,Apple,Microsoft"
      ~api_key text
  in
  print_entities "Companies" companies;
  Lwt.return_unit

let () =
  match Sys.getenv_opt "GOOGLE_API_KEY" with
  | None -> print_endline "Error: GOOGLE_API_KEY environment variable not set."
  | Some api_key -> (
    match Array.to_list Sys.argv with
    | _ :: prompt :: _ ->
      print_endline "Prompt provided. Running direct completion:";
      let r = Lwt_main.run (completion ~api_key prompt) in
      (match r with
       | Ok text -> Printf.printf "Response:\n\n%s\n" text
       | Error e -> Printf.printf "API Call Failed:\n%s\n" e)
    | _ ->
      print_endline "No prompt provided. Running demo extraction on sample text:";
      Lwt_main.run (run_demo ~api_key))
