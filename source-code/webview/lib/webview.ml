(* A tiny "web view" host. The Haskell webkit-haskell library opened a native
   WebKit window and let JavaScript call registered handlers over a C bridge
   (window.webkit_haskell.invoke). There is no clean WebKitGTK binding in the
   OCaml stack, so here the same idea runs as a Dream web app: the page loads in
   the browser and invoke() POSTs to /bridge/<command>. *)

open Lwt.Syntax

type app = { handlers : (string, Yojson.Safe.t -> Yojson.Safe.t) Hashtbl.t }

let create () = { handlers = Hashtbl.create 16 }
let register app command handler = Hashtbl.replace app.handlers command handler

(* Look up and run a handler, turning exceptions into an error object. *)
let dispatch app command payload =
  match Hashtbl.find_opt app.handlers command with
  | Some h -> (
    try h payload
    with e -> `Assoc [ ("error", `String (Printexc.to_string e)) ])
  | None -> `Assoc [ ("error", `String ("Unknown command: " ^ command)) ]

(* The browser-side shim, served at /bridge.js. *)
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
