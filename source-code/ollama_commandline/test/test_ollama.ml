let contains s sub =
  let len = String.length sub in
  let rec search i =
    if i + len > String.length s then false
    else if String.sub s i len = sub then true
    else search (i + 1)
  in
  search 0

let decode_response () =
  let json_str = {|
{
  "model": "qwen3.5:4b",
  "created_at": "2024-01-01T00:00:00Z",
  "response": "Hello!",
  "done": true
}
|} in
  let json = Yojson.Safe.from_string json_str in
  match Ollama.response_of_yojson json with
  | Ok r ->
    Alcotest.(check string) "model" "qwen3.5:4b" r.Ollama.resp_model;
    Alcotest.(check string) "created_at" "2024-01-01T00:00:00Z"
      r.Ollama.resp_created_at;
    Alcotest.(check string) "response" "Hello!" r.Ollama.resp_response;
    Alcotest.(check bool) "done" true r.Ollama.resp_done;
    Alcotest.(check (option string)) "done_reason" None
      r.Ollama.resp_done_reason
  | Error e -> Alcotest.fail ("Failed to decode: " ^ e)

let decode_response_with_done_reason () =
  let json_str =
    {|{"model":"x","created_at":"","response":"","done":true,"done_reason":"stop"}|}
  in
  let json = Yojson.Safe.from_string json_str in
  match Ollama.response_of_yojson json with
  | Ok r ->
    Alcotest.(check (option string)) "done_reason" (Some "stop")
      r.Ollama.resp_done_reason
  | Error e -> Alcotest.fail ("Failed to decode: " ^ e)

let decode_error () =
  let json_str = {|{"error":"model not found"}|} in
  let json = Yojson.Safe.from_string json_str in
  match Ollama.error_of_yojson json with
  | Ok e ->
    Alcotest.(check string) "error msg" "model not found" e.Ollama.err_msg
  | Error e -> Alcotest.fail ("Failed to decode: " ^ e)

let encode_request () =
  let req = Ollama.{ model = "qwen3"; prompt = "Hi"; stream = false } in
  let json = Ollama.request_to_yojson req in
  let json_str = Yojson.Safe.to_string ~std:true json in
  Alcotest.(check bool) "has model field" (contains json_str "\"model\"") true;
  Alcotest.(check bool) "has prompt field" (contains json_str "\"prompt\"") true;
  Alcotest.(check bool) "has stream field" (contains json_str "\"stream\"") true

let encode_request_with_text () =
  let req = Ollama.{ model = "m"; prompt = "Hello"; stream = true } in
  let json = Ollama.request_to_yojson req in
  let json_str = Yojson.Safe.to_string ~std:true json in
  Alcotest.(check bool) "contains user text"
    (contains json_str "Hello") true

let tests =
  [ "decode complete OllamaResponse", `Quick, decode_response
  ; "decode OllamaResponse with done_reason", `Quick,
    decode_response_with_done_reason
  ; "decode OllamaError", `Quick, decode_error
  ; "encode OllamaRequest with correct field names", `Quick, encode_request
  ; "encode request containing user text", `Quick, encode_request_with_text
  ]

let () = Alcotest.run "Ollama" [("Ollama JSON", tests)]
