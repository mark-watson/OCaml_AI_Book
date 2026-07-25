let call_ollama model prompt =
  let json = Ollama.request_to_yojson
    { Ollama.model; prompt; stream = false }
  in
  let body_str = Yojson.Safe.to_string ~std:true json in
  let uri = Uri.of_string "http://localhost:11434/api/generate" in
  let headers = Cohttp.Header.of_list [("content-type", "application/json")] in
  let body = Cohttp_lwt.Body.of_string body_str in
  let open Lwt.Infix in
  let http_call () =
    Cohttp_lwt_unix.Client.post ~body ~headers uri
    >>= fun (resp, resp_body) ->
    let status = Cohttp.Response.status resp in
    let code = Cohttp.Code.code_of_status status in
    Cohttp_lwt.Body.to_string resp_body
    >>= fun body_str ->
    if Cohttp.Code.is_success code then
      match Yojson.Safe.from_string body_str |> Ollama.response_of_yojson with
      | Ok r -> Lwt.return_ok r
      | Error e -> Lwt.return_error ("JSON parse error: " ^ e)
    else
      let err_msg =
        match Yojson.Safe.from_string body_str |> Ollama.error_of_yojson with
        | Ok e -> e.Ollama.err_msg
        | Error _ -> body_str
      in
      Lwt.return_error ("HTTP " ^ string_of_int code ^ ": " ^ err_msg)
  in
  Lwt.catch http_call (fun _ ->
    Lwt.return_error
      "Could not connect to Ollama. Please ensure the Ollama service is running \
       on port 11434.")

let run prompt model =
  Printf.printf "Sending prompt '%s' to model '%s'...\n%!" prompt model;
  let result = Lwt_main.run (call_ollama model prompt) in
  match result with
  | Ok r ->
    print_endline "\n--- Response ---";
    print_endline r.Ollama.resp_response;
    (match r.Ollama.resp_done_reason with
     | Some reason -> Printf.printf "\nDone reason: %s\n" reason
     | None -> ())
  | Error err -> Printf.printf "API Error: %s\n" err

let () =
  let args = List.tl (Array.to_list Sys.argv) in
  match args with
  | [] ->
    Printf.eprintf "Usage: %s <prompt> [model_name]\n" Sys.argv.(0);
    exit 1
  | prompt :: rest ->
    let model = match rest with m :: _ -> m | [] -> "qwen3.5:4b" in
    run prompt model
