(* A small Dream web app: serve a chat page, and POST /chat forwards the prompt
   to the Gemini API and returns its text. Haskell used Scotty; Dream is the
   OCaml equivalent. Set GOOGLE_API_KEY before running. *)

open Lwt.Syntax

let endpoint = Chat.endpoint_for Chat.default_model

let call_gemini ~api_key prompt =
  let body = Yojson.Safe.to_string (Chat.gemini_request prompt) in
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
      let* s = Cohttp_lwt.Body.to_string rbody in
      let code = Cohttp.Code.code_of_status (Cohttp.Response.status resp) in
      if code = 200 then Lwt.return (Chat.text_of_json (Yojson.Safe.from_string s))
      else Lwt.return (Error (Printf.sprintf "API request failed with status %d" code)))
    (fun exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn)))

let () =
  match Sys.getenv_opt "GOOGLE_API_KEY" with
  | None ->
    print_endline "Error: GOOGLE_API_KEY environment variable not set.";
    print_endline "Please set it with: export GOOGLE_API_KEY=your-key-here";
    exit 1
  | Some api_key ->
    Dream.run ~interface:"127.0.0.1" ~port:3000
    @@ Dream.logger
    @@ Dream.router
         [ Dream.get "/" (fun _ -> Dream.html Chat.page);
           Dream.post "/chat" (fun request ->
               let* body = Dream.body request in
               let* result = call_gemini ~api_key (Chat.prompt_of_body body) in
               match result with
               | Ok text ->
                 Dream.json
                   (Yojson.Safe.to_string (`Assoc [ ("text", `String text) ]))
               | Error e ->
                 Dream.json ~status:`Internal_Server_Error
                   (Yojson.Safe.to_string (`Assoc [ ("error", `String e) ])))
         ]
