type ollama_request = {
  model : string;
  prompt : string;
  stream : bool;
}

type ollama_response = {
  resp_model : string;
  resp_created_at : string;
  resp_response : string;
  resp_done : bool;
  resp_done_reason : string option;
}

type ollama_error = {
  err_msg : string;
}

let request_to_yojson req =
  `Assoc
    [ ("model", `String req.model)
    ; ("prompt", `String req.prompt)
    ; ("stream", `Bool req.stream)
    ]

let response_of_yojson json =
  let open Yojson.Safe.Util in
  try
    let m = json |> member "model" |> to_string in
    let c = json |> member "created_at" |> to_string in
    let r = json |> member "response" |> to_string in
    let d = json |> member "done" |> to_bool in
    let dr =
      match json |> member "done_reason" with
      | `Null -> None
      | v -> Some (to_string v)
    in
    Ok { resp_model = m; resp_created_at = c; resp_response = r
       ; resp_done = d; resp_done_reason = dr }
  with
  | _ -> Error "failed to parse OllamaResponse"

let error_of_yojson json =
  let open Yojson.Safe.Util in
  try
    let m = json |> member "error" |> to_string in
    Ok { err_msg = m }
  with
  | _ -> Error "failed to parse OllamaError"
