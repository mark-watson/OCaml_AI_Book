(* Hello world: a page plus one bridge handler that echoes a greeting. OCaml
   port of the Haskell webkit-haskell HelloWorld example. *)

let page =
  {html|<!DOCTYPE html>
<html>
<head><meta charset='utf-8'><title>Hello</title>
<script src='/bridge.js'></script></head>
<body style='font-family: system-ui, sans-serif; text-align: center; margin-top: 4rem;'>
  <h1>Hello from a Dream web view</h1>
  <input id='name' placeholder='your name'>
  <button onclick='greet()'>Greet</button>
  <p id='out'></p>
  <script>
    async function greet() {
      const name = document.getElementById('name').value;
      const r = await window.webkit_haskell.invoke('greet', { name: name });
      document.getElementById('out').textContent = r.message;
    }
  </script>
</body>
</html>|html}

let () =
  let app = Webview.create () in
  Webview.register app "greet" (fun payload ->
      let name =
        match payload with
        | `Assoc kv -> (
          match List.assoc_opt "name" kv with Some (`String s) -> s | _ -> "")
        | _ -> ""
      in
      let name = if name = "" then "world" else name in
      `Assoc [ ("message", `String ("Hello, " ^ name ^ "!")) ]);
  print_endline "Hello app on http://127.0.0.1:8080/";
  Webview.run app ~page
