let response =
  {|{"candidates":[{"content":{"parts":[{"text":"Hello!"}]}}]}|}

let test_text () =
  match Chat.text_of_json (Yojson.Safe.from_string response) with
  | Ok s -> Alcotest.(check string) "text" "Hello!" s
  | Error e -> Alcotest.fail e

let test_prompt () =
  Alcotest.(check string) "prompt" "hi there"
    (Chat.prompt_of_body {|{"prompt":"hi there"}|})

let test_request () =
  let open Yojson.Safe.Util in
  let text =
    Chat.gemini_request "q" |> member "contents" |> to_list |> List.hd
    |> member "parts" |> to_list |> List.hd |> member "text" |> to_string
  in
  Alcotest.(check string) "prompt embedded" "q" text

let test_endpoint () =
  Alcotest.(check string) "endpoint"
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent"
    (Chat.endpoint_for Chat.default_model)

let () =
  Alcotest.run "webchat"
    [ ( "chat",
        [ Alcotest.test_case "response text" `Quick test_text;
          Alcotest.test_case "prompt parse" `Quick test_prompt;
          Alcotest.test_case "request shape" `Quick test_request;
          Alcotest.test_case "endpoint" `Quick test_endpoint ] ) ]
