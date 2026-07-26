# Using Large Language Model APIs

This chapter builds command-line clients for three large language model APIs: a local [Ollama](https://ollama.com/) model, the OpenAI chat API, and the Google Gemini API. All three follow one pattern, so once you have written one you can write any of them:

1. Build the request as JSON with Yojson.
2. POST it with Cohttp over Lwt.
3. Decode the response with Yojson, returning a `result`.
4. Read the API key from the environment, and turn every failure into a clear message.

There is no special SDK here. A REST endpoint plus a hand-written JSON codec is all you need, and doing it by hand shows exactly what goes over the wire. The examples are in `source-code/ollama_commandline/`, `source-code/OpenAiApiClient/`, and `source-code/gemini_commandline/`.

## A Local Ollama Client

Ollama runs a model on your own machine and serves it at `http://localhost:11434`. The file `lib/ollama.ml` defines records for the request, the response, and an error, then a codec for each. The request encoder is direct:

```ocaml
let request_to_yojson req =
  `Assoc
    [ ("model", `String req.model)
    ; ("prompt", `String req.prompt)
    ; ("stream", `Bool req.stream)
    ]
```

The response decoder reads each field and returns a `result`, so a malformed reply becomes an `Error` instead of an exception. Note how it handles an optional field:

```ocaml
let response_of_yojson json =
  let open Yojson.Safe.Util in
  try
    let m = json |> member "model" |> to_string in
    ...
    let dr =
      match json |> member "done_reason" with
      | `Null -> None
      | v -> Some (to_string v)
    in
    Ok { resp_model = m; ...; resp_done_reason = dr }
  with
  | _ -> Error "failed to parse OllamaResponse"
```

`member "done_reason"` returns `` `Null `` when the field is absent, which maps to `None`; otherwise the value maps to `Some`. Wrapping the whole read in a `try` turns any decode slip into the `Error` case.

The program in `bin/main.ml` makes the HTTP call. This client uses the `Lwt.Infix` operators, so promises chain with `>>=` rather than `let*`; the two styles are equivalent:

```ocaml
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
    ...
```

It POSTs the request, checks the status code, and decodes the body on success. If the call cannot connect at all, `Lwt.catch` reports that the Ollama service is not running, which is the common first-run problem. The command line takes a prompt and an optional model name:

```bash
cd source-code/ollama_commandline
dune exec bin/main.exe -- "What is the capital of France?"
dune exec bin/main.exe -- "Explain monads" "llama3.2"
```

The `--` separates dune's arguments from your program's. With one argument it uses a default model; with two it uses the model you name.

## An OpenAI Chat Client

The OpenAI client, in `OpenAiApiClient/`, calls the chat-completion endpoint. The codec in `lib/openai.ml` is smaller because the request is simpler: a model and a list of messages:

```ocaml
let chat_request_json ~model ~prompt =
  `Assoc
    [ ("model", `String model);
      ( "messages",
        `List
          [ `Assoc [ ("role", `String "user"); ("content", `String prompt) ] ] )
    ]
```

Reading the reply pulls the text out of `choices[0].message.content`, and falls back to the API's own error message when the shape is different:

```ocaml
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
```

The `exception _` case is a nice touch: if reading `choices` throws because the response is actually an error object, it reads `error.message` instead and returns that as the `Error`. So an API error like an invalid key comes back as a readable string, not a crash.

The program posts to the endpoint with a Bearer token header and decodes on a 2xx status. It reads the key from the environment first, so a missing key fails early with instructions:

```ocaml
let () =
  match Sys.getenv_opt "OPENAI_API_KEY" with
  | None ->
    print_endline "Error: OPENAI_API_KEY environment variable not set.";
    ...
    exit 1
  | Some api_key -> ...
```

## A Gemini Client

The Gemini client, in `gemini_commandline/`, calls the `generateContent` endpoint. Its codec in `lib/gemini.ml` builds a request with optional temperature and token limits, using OCaml's optional arguments:

```ocaml
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
```

The `?(temperature = 0.1)` gives a default, so callers pass only the prompt. Reading the reply walks down to `candidates[0].content.parts[0].text`, and when there are no candidates it checks whether the prompt was blocked, so a safety block gives a clear reason:

```ocaml
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
```

## Entity Extraction With a Model

Both the OpenAI and Gemini clients show a small but useful trick: ask the model to return a comma-separated list, then parse it. Each codec has the same `split_entities`:

```ocaml
let split_entities response =
  String.split_on_char ',' response
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
```

The Gemini demo wraps this in `extract_entities`, which builds a prompt that names the kind of entity and gives an example, then maps `split_entities` over the result:

```ocaml
let extract_entities ~kind ~example ~api_key text =
  let prompt =
    Printf.sprintf
      "Extract only the %s strictly separated by commas from the following \
       text. Do not include any explanation or introduction. Example: %s\n\n\
       Text:\"%s\""
      kind example text
  in
  let* r = completion ~api_key prompt in
  Lwt.return (Result.map Gemini.split_entities r)
```

`Result.map` applies `split_entities` only when the call succeeded, and leaves an `Error` untouched, so the parsing never runs on a failed request. The labelled arguments `~kind` and `~example` make each call read clearly:

```ocaml
let* places =
  extract_entities ~kind:"place names" ~example:"London,Paris,Tokyo" ~api_key text
in
print_entities "Places" places;
```

With no command-line argument the Gemini demo runs this extraction on a sample paragraph, pulling out places, people, and companies. With an argument it runs that text as a single completion. This is the same task the classic NLP toolkit in Chapter 7 does with lexicons; here a model does it from a prompt.

## Running the Clients

Each client needs its service or key. Ollama needs a running local server:

```bash
cd source-code/ollama_commandline
dune exec bin/main.exe -- "What is the capital of France?"
```

OpenAI and Gemini need an API key in the environment:

```bash
cd source-code/OpenAiApiClient
export OPENAI_API_KEY=sk-...
dune exec ./bin/main.exe

cd ../gemini_commandline
export GOOGLE_API_KEY=your-key-here
dune exec ./bin/main.exe                 # demo entity extraction
dune exec ./bin/main.exe -- "Explain OCaml functors"
```

Every one of these clients keeps its codec pure and separate from the HTTP call, so the tests exercise the JSON encode and decode offline, with no key and no network. That separation is the single most useful habit in this chapter: build and parse JSON in pure functions you can test, and let a thin Lwt wrapper do the I/O.
