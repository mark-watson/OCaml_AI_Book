(* JSON codec for the Gemini generateContent API. The Haskell version derived
   FromJSON/ToJSON via Generics; here we build and read the JSON by hand. *)

(* The model is named once here; change it to try another Gemini model. *)
let default_model = "gemini-3.5-flash"

let endpoint_for model =
  "https://generativelanguage.googleapis.com/v1beta/models/" ^ model
  ^ ":generateContent"

let request_json ?(temperature = 0.1) ?(max_output_tokens = 800) prompt =
  `Assoc
    [ ( "contents",
        `List
          [ `Assoc
              [ ("parts", `List [ `Assoc [ ("text", `String prompt) ] ]) ] ] );
      ( "generationConfig",
        `Assoc
          [ ("temperature", `Float temperature);
            ("maxOutputTokens", `Int max_output_tokens) ] )
    ]

(* Extract candidates[0].content.parts[0].text, or report why it is missing. *)
let text_of_json json =
  let open Yojson.Safe.Util in
  match json |> member "candidates" |> to_list with
  | candidate :: _ -> (
    match candidate |> member "content" |> member "parts" |> to_list with
    | part :: _ -> Ok (part |> member "text" |> to_string)
    | [] -> Error "candidate with no parts")
  | [] -> (
    match json |> member "promptFeedback" |> member "blockReason" with
    | `String r -> Error ("Blocked - " ^ r)
    | _ -> Error "no candidates found in response")
  | exception _ -> Error "unexpected response shape"

let split_entities response =
  String.split_on_char ',' response
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
