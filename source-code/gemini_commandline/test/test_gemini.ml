let sample =
  {|{"candidates":[{"content":{"parts":[{"text":"London, Paris, Tokyo"}]}}]}|}

let blocked = {|{"candidates":[],"promptFeedback":{"blockReason":"SAFETY"}}|}

let test_text () =
  match Gemini.text_of_json (Yojson.Safe.from_string sample) with
  | Ok s -> Alcotest.(check string) "text" "London, Paris, Tokyo" s
  | Error e -> Alcotest.fail e

let test_blocked () =
  match Gemini.text_of_json (Yojson.Safe.from_string blocked) with
  | Ok _ -> Alcotest.fail "expected a block error"
  | Error e -> Alcotest.(check string) "block reason" "Blocked - SAFETY" e

let test_request_shape () =
  let json = Gemini.request_json "hi" in
  let open Yojson.Safe.Util in
  let text =
    json |> member "contents" |> to_list |> List.hd |> member "parts"
    |> to_list |> List.hd |> member "text" |> to_string
  in
  Alcotest.(check string) "prompt embedded" "hi" text

let () =
  Alcotest.run "gemini"
    [ ( "codec",
        [ Alcotest.test_case "text" `Quick test_text;
          Alcotest.test_case "blocked" `Quick test_blocked;
          Alcotest.test_case "request" `Quick test_request_shape ] ) ]
