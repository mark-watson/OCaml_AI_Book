let sample =
  {|{"choices":[{"message":{"role":"assistant","content":"London, Paris, New York"}}]}|}

let test_content () =
  match Openai.content_of_json (Yojson.Safe.from_string sample) with
  | Ok s -> Alcotest.(check string) "content" "London, Paris, New York" s
  | Error e -> Alcotest.fail e

let test_error () =
  let err = {|{"error":{"message":"bad key"}}|} in
  match Openai.content_of_json (Yojson.Safe.from_string err) with
  | Ok _ -> Alcotest.fail "expected an error"
  | Error e -> Alcotest.(check string) "error message" "bad key" e

let test_split () =
  Alcotest.(check (list string))
    "split" [ "London"; "Paris"; "New York" ]
    (Openai.split_entities "London, Paris, New York")

let () =
  Alcotest.run "OpenAiApiClient"
    [ ( "codec",
        [ Alcotest.test_case "content" `Quick test_content;
          Alcotest.test_case "error" `Quick test_error;
          Alcotest.test_case "split" `Quick test_split ] ) ]
