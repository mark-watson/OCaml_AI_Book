(* Call the OpenAI chat-completion endpoint, then extract place and person
   names from sample text. Set OPENAI_API_KEY before running. *)

open Lwt.Syntax

let endpoint = "https://api.openai.com/v1/chat/completions"

let complete ~api_key ~model ~prompt =
  let body = Yojson.Safe.to_string (Openai.chat_request_json ~model ~prompt) in
  let headers =
    Cohttp.Header.of_list
      [ ("content-type", "application/json");
        ("authorization", "Bearer " ^ api_key) ]
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
      if code >= 200 && code < 300 then
        Lwt.return (Openai.content_of_json (Yojson.Safe.from_string rbody_str))
      else Lwt.return (Error (Printf.sprintf "HTTP %d: %s" code rbody_str)))
    (fun exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn)))

let find kind ~api_key text =
  let prompt =
    Printf.sprintf
      "Extract only the %s separated by commas from the following text:\n\n%s"
      kind text
  in
  let* r = complete ~api_key ~model:Openai.default_model ~prompt in
  Lwt.return (Result.map Openai.split_entities r)

let print_result label = function
  | Ok items -> Printf.printf "%s: [%s]\n" label (String.concat "; " items)
  | Error e -> Printf.printf "%s error: %s\n" label e

let () =
  match Sys.getenv_opt "OPENAI_API_KEY" with
  | None ->
    print_endline "Error: OPENAI_API_KEY environment variable not set.";
    print_endline "Please set it with: export OPENAI_API_KEY=sk-...";
    exit 1
  | Some api_key ->
    Lwt_main.run
      (let* gen =
         complete ~api_key ~model:Openai.default_model
           ~prompt:"Write a hello world program in OCaml"
       in
       (match gen with
        | Ok s -> print_endline s
        | Error e -> Printf.printf "Error: %s\n" e);
       let* places =
         find "place names" ~api_key
           "I visited London, Paris, and New York last year."
       in
       print_result "Places" places;
       let* people =
         find "person names" ~api_key
           "John Smith met with Sarah Johnson and Michael Brown at the conference."
       in
       print_result "People" people;
       Lwt.return_unit)
