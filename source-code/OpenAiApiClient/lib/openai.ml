(* JSON codec for the OpenAI chat-completion API. The Haskell version used the
   openai-hs library; here we build the small request and pick apart the
   response with Yojson, the same manual-codec style as the Ollama example. *)

let default_model = "gpt-5-mini"

let chat_request_json ~model ~prompt =
  `Assoc
    [ ("model", `String model);
      ( "messages",
        `List
          [ `Assoc [ ("role", `String "user"); ("content", `String prompt) ] ] )
    ]

(* Pull choices[0].message.content out of a response, or report the API error. *)
let content_of_json json =
  let open Yojson.Safe.Util in
  match json |> member "choices" |> to_list with
  | choice :: _ -> (
    match choice |> member "message" |> member "content" with
    | `String s -> Ok s
    | _ -> Error "no content in first choice")
  | [] -> Error "no choices returned"
  | exception _ -> (
    match json |> member "error" |> member "message" with
    | `String s -> Error s
    | _ -> Error "unexpected response shape")

(* Split a comma-separated model reply into trimmed, non-empty items. *)
let split_entities response =
  String.split_on_char ',' response
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
