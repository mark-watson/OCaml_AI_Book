(* Counter app: JavaScript buttons call backend handlers over the bridge.
   OCaml port of the Haskell webkit-haskell CounterApp. Open the printed URL. *)

let page =
  {html|<!DOCTYPE html>
<html>
<head><meta charset='utf-8'><title>Counter</title>
<style>
  body { font-family: system-ui, sans-serif; background: #0a0a0a; color: #fafafa;
         display: flex; flex-direction: column; align-items: center;
         justify-content: center; height: 100vh; gap: 24px; }
  #counter { font-size: 5rem; font-weight: 800; }
  .controls { display: flex; gap: 12px; }
  button { font-size: 1.1rem; padding: 10px 24px; border: none; border-radius: 10px;
           cursor: pointer; }
  .info { font-size: 0.8rem; color: #888; text-align: center; }
</style>
<script src='/bridge.js'></script>
</head>
<body>
  <h2>Counter</h2>
  <div id='counter'>0</div>
  <div class='controls'>
    <button onclick='decrement()'>- Minus</button>
    <button onclick='reset()'>Reset</button>
    <button onclick='increment()'>+ Plus</button>
  </div>
  <div class='info' id='info'>Loading backend info...</div>
  <script>
    const display = document.getElementById('counter');
    const info = document.getElementById('info');
    const set = (r) => { display.textContent = r.count; };
    async function increment() { set(await window.webkit_haskell.invoke('increment', {})); }
    async function decrement() { set(await window.webkit_haskell.invoke('decrement', {})); }
    async function reset() { set(await window.webkit_haskell.invoke('reset', {})); }
    async function init() {
      set(await window.webkit_haskell.invoke('get-count', {}));
      const s = await window.webkit_haskell.invoke('get-system-info', {});
      info.innerHTML = 'Backend: ' + s.language + ' v' + s.version +
        '<br>Platform: ' + s.os + ' (' + s.arch + ')';
    }
    init();
  </script>
</body>
</html>|html}

let () =
  let app = Webview.create () in
  let count = ref 0 in
  let counted () = `Assoc [ ("count", `Int !count) ] in
  Webview.register app "increment" (fun _ -> incr count; counted ());
  Webview.register app "decrement" (fun _ -> decr count; counted ());
  Webview.register app "reset" (fun _ -> count := 0; counted ());
  Webview.register app "get-count" (fun _ -> counted ());
  Webview.register app "get-system-info" (fun _ ->
      `Assoc
        [ ("language", `String "OCaml");
          ("version", `String Sys.ocaml_version);
          ("os", `String Sys.os_type);
          ("arch", `String (string_of_int Sys.word_size ^ "-bit")) ]);
  print_endline "Counter app on http://127.0.0.1:8080/";
  Webview.run app ~page
