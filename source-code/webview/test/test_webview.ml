let test_dispatch () =
  let app = Webview.create () in
  Webview.register app "double" (fun p ->
      match p with
      | `Assoc kv -> (
        match List.assoc_opt "n" kv with
        | Some (`Int n) -> `Assoc [ ("r", `Int (n * 2)) ]
        | _ -> `Null)
      | _ -> `Null);
  (match Webview.dispatch app "double" (`Assoc [ ("n", `Int 21) ]) with
   | `Assoc [ ("r", `Int r) ] -> Alcotest.(check int) "doubled" 42 r
   | _ -> Alcotest.fail "unexpected result");
  match Webview.dispatch app "missing" `Null with
  | `Assoc [ ("error", `String _) ] -> ()
  | _ -> Alcotest.fail "expected an error object"

let () =
  Alcotest.run "webview"
    [ ("bridge", [ Alcotest.test_case "dispatch" `Quick test_dispatch ]) ]
