# Networking and Web Applications

This chapter moves from a single program to programs that talk to each other. It starts with a raw TCP server and client built on Lwt sockets, in `source-code/ClientServer/`. Then it builds two web applications on [Dream](https://aantron.github.io/dream/), a modern OCaml web framework: a "web view" app with a JavaScript bridge, in `source-code/webview/`, and a chat app that forwards prompts to the Google Gemini API, in `source-code/webchat/`.

## A TCP Server and Client

The server in `server.ml` reverses every chunk of bytes a client sends. It uses `Lwt_unix`, which is the standard Unix socket calls in Lwt form, so `recv` and `send` map straight onto the system calls. First, the per-connection loop:

```ocaml
let rec reverse_loop sock =
  let buf = Bytes.create 4096 in
  let* n = Lwt_unix.recv sock buf 0 4096 [] in
  if n = 0 then Lwt.return_unit
  else
    let* _ = Lwt_unix.send sock (reverse_bytes buf n) 0 n [] in
    reverse_loop sock
```

`Lwt_unix.recv` reads up to 4096 bytes into a buffer and returns how many it got. A count of zero means the client closed the connection, so the loop ends. Otherwise it sends back the reversed bytes and loops. The setup opens a socket, allows address reuse, binds to the loopback address, and accepts connections in a loop:

```ocaml
let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true;
let addr = Unix.(ADDR_INET (inet_addr_loopback, 3000)) in
let* () = Lwt_unix.bind sock addr in
Lwt_unix.listen sock 10;
...
let rec accept_loop () =
  let* client, caddr = Lwt_unix.accept sock in
  Printf.printf "Connection from %s\n%!" (string_of_addr caddr);
  Lwt.async (fun () ->
      Lwt.finalize
        (fun () -> reverse_loop client)
        (fun () -> Lwt_unix.close client));
  accept_loop ()
```

Two Lwt functions handle concurrency. `Lwt.async` starts a lightweight thread for each client and moves on, so one slow client never blocks the accept loop. `Lwt.finalize` runs its second function no matter how the first ends, so the client socket always closes. Binding to `inet_addr_loopback` keeps the server on `127.0.0.1`, not exposed to the network.

The client in `client.ml` is the mirror image: connect, send a message, print the reply:

```ocaml
let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
let addr = Unix.(ADDR_INET (inet_addr_loopback, 3000)) in
let* () = Lwt_unix.connect sock addr in
print_endline "Connection established to 127.0.0.1:3000";
let msg = Bytes.of_string "test123" in
let* _ = Lwt_unix.send sock msg 0 (Bytes.length msg) [] in
let buf = Bytes.create 100 in
let* n = Lwt_unix.recv sock buf 0 100 [] in
...
Printf.printf "Response: %s\n" (Bytes.sub_string buf 0 n);
```

Run the server in one terminal and the client in another:

```bash
cd source-code/ClientServer
dune exec ./server.exe    # terminal 1
dune exec ./client.exe    # terminal 2
```

The client sends `test123` and prints `Response: 321tset`, the reversed bytes.

## Web Applications with Dream

Dream serves HTTP with a simple shape: you build a pipeline of `Dream.run`, some middleware like `Dream.logger`, and a `Dream.router` that maps routes to handlers. A handler takes a request and returns a response promise. The next two examples use this shape.

One OCaml detail makes web code pleasant: quoted string literals. Writing `{html|...|html}` gives you a string delimited by `|html}` instead of double quotes, so you can paste HTML or JavaScript inside with no escaping. The examples use `{html|...|html}`, `{js|...|js}`, and `{page|...|page}` to hold their front-end code.

## A Web View With a JavaScript Bridge

The `webview` example recreates a native "web view" idea as a Dream app. A browser page calls backend handlers through a small JavaScript shim that POSTs to the server. The host, in `lib/webview.ml`, keeps a table of named handlers, each a function from a JSON payload to a JSON result:

```ocaml
type app = { handlers : (string, Yojson.Safe.t -> Yojson.Safe.t) Hashtbl.t }

let create () = { handlers = Hashtbl.create 16 }
let register app command handler = Hashtbl.replace app.handlers command handler

let dispatch app command payload =
  match Hashtbl.find_opt app.handlers command with
  | Some h -> (
    try h payload
    with e -> `Assoc [ ("error", `String (Printexc.to_string e)) ])
  | None -> `Assoc [ ("error", `String ("Unknown command: " ^ command)) ]
```

`register` adds a handler under a command name. `dispatch` looks one up and runs it, turning an unknown command or a thrown exception into a JSON error object, so a bad request never crashes the server. The browser shim, served at `/bridge.js`, gives the page one function that POSTs to `/bridge/<command>`:

```ocaml
let bridge_js =
  {js|window.webkit_haskell = {
  invoke: async function (command, payload) {
    const r = await fetch('/bridge/' + command, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload || {})
    });
    return await r.json();
  }
};
|js}
```

The router wires three routes: the page, the bridge script, and the POST endpoint that dispatches to a handler:

```ocaml
let run ?(port = 8080) app ~page =
  Dream.run ~interface:"127.0.0.1" ~port
  @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/" (fun _ -> Dream.html page);
         Dream.get "/bridge.js" (fun _ ->
             Dream.respond
               ~headers:[ ("Content-Type", "application/javascript") ]
               bridge_js);
         Dream.post "/bridge/:command" (fun req ->
             let command = Dream.param req "command" in
             let* body = Dream.body req in
             let payload = try Yojson.Safe.from_string body with _ -> `Null in
             Dream.json (Yojson.Safe.to_string (dispatch app command payload)))
       ]
```

The route `/bridge/:command` has a path parameter, read with `Dream.param req "command"`. The handler reads the request body, parses it as JSON, and returns the dispatch result as JSON. The `@@` operators chain the pipeline: run wraps logger wraps router.

The counter app in `bin/counter.ml` supplies the page and the handlers. It keeps the count in a mutable `ref` and registers one handler per button:

```ocaml
let app = Webview.create () in
let count = ref 0 in
let counted () = `Assoc [ ("count", `Int !count) ] in
Webview.register app "increment" (fun _ -> incr count; counted ());
Webview.register app "decrement" (fun _ -> decr count; counted ());
Webview.register app "reset" (fun _ -> count := 0; counted ());
Webview.register app "get-count" (fun _ -> counted ());
Webview.register app "get-system-info" (fun _ -> ...);
```

Each handler updates the count and returns it as JSON. The page's JavaScript calls `window.webkit_haskell.invoke('increment', {})` when you click a button, and updates the display with the returned count. Run it and open the printed URL:

```bash
cd source-code/webview
dune exec ./bin/counter.exe   # then open http://127.0.0.1:8080/
```

## A Chat App Backed by Gemini

The `webchat` example serves a chat page and forwards each prompt to the Gemini API. It splits into a pure codec, in `lib/chat.ml`, and the server, in `bin/main.ml`. Keeping the codec pure lets the tests run with no server and no API key.

The codec builds the Gemini request body and reads the response text. Both are plain Yojson:

```ocaml
let gemini_request prompt =
  `Assoc
    [ ( "contents",
        `List
          [ `Assoc [ ("parts", `List [ `Assoc [ ("text", `String prompt) ] ]) ] ] );
      ( "generationConfig",
        `Assoc
          [ ("temperature", `Float 0.1); ("maxOutputTokens", `Int 800) ] )
    ]

let text_of_json json =
  let open Yojson.Safe.Util in
  match json |> member "candidates" |> to_list with
  | candidate :: _ -> (
    match candidate |> member "content" |> member "parts" |> to_list with
    | part :: _ -> Ok (part |> member "text" |> to_string)
    | [] -> Error "No content in response")
  | [] -> Error "No candidates in response"
  | exception _ -> Error "Failed to parse Gemini response"
```

`text_of_json` returns a `result`, and its final `exception _` case turns a malformed response into an `Error` rather than a crash. The server posts the request to Gemini and returns the reply as JSON:

```ocaml
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
```

The main function reads the API key from the environment, exits with a clear message if it is missing, and otherwise starts a Dream server with two routes: the page, and a `/chat` POST that calls Gemini and returns the text:

```ocaml
Dream.post "/chat" (fun request ->
    let* body = Dream.body request in
    let* result = call_gemini ~api_key (Chat.prompt_of_body body) in
    match result with
    | Ok text ->
      Dream.json (Yojson.Safe.to_string (`Assoc [ ("text", `String text) ]))
    | Error e ->
      Dream.json ~status:`Internal_Server_Error
        (Yojson.Safe.to_string (`Assoc [ ("error", `String e) ])))
```

Set the key and run it:

```bash
cd source-code/webchat
export GOOGLE_API_KEY=your-key-here
dune exec ./bin/main.exe       # then open http://127.0.0.1:3000/
dune runtest                   # codec tests, no key needed
```

Type a prompt in the page and the reply appears below it. The next chapter covers the Gemini API and two other model APIs from the command line, using the same request-and-decode pattern you just saw in the chat codec.
