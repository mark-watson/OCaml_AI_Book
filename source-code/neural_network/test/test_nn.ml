open Nn

let test_shapes () =
  let net = Mlp.create [ 3; 5; 2 ] in
  Alcotest.(check int) "two layers" 2 (Array.length net);
  Alcotest.(check int) "hidden units" 5 (Array.length net.(0).w);
  Alcotest.(check int) "inputs per hidden unit" 3 (Array.length net.(0).w.(0));
  let out = Mlp.predict net [| 0.1; 0.2; 0.3 |] in
  Alcotest.(check int) "two outputs" 2 (Array.length out);
  Alcotest.(check bool) "outputs are probabilities" true
    (Array.for_all (fun p -> p > 0. && p < 1.) out)

(* The standard check on a backpropagation implementation: nudge each weight
   up and down by a tiny amount, measure how the loss changes, and compare
   that slope with the gradient backprop computed. *)
let test_gradient_check () =
  let net = Mlp.create ~seed:3 [ 2; 3; 1 ] in
  let x = [| 0.4; -0.7 |] and t = [| 1. |] in
  let grads = Mlp.backprop net x t in
  let h = 1e-5 in
  Array.iteri
    (fun k l ->
      Array.iteri
        (fun j row ->
          Array.iteri
            (fun i w ->
              row.(i) <- w +. h;
              let up = Mlp.example_loss net x t in
              row.(i) <- w -. h;
              let down = Mlp.example_loss net x t in
              row.(i) <- w;
              let numeric = (up -. down) /. (2. *. h) in
              let analytic = grads.(k).dw.(j).(i) in
              Alcotest.(check (float 1e-6))
                (Printf.sprintf "dw layer %d [%d][%d]" k j i)
                numeric analytic)
            row)
        l.Mlp.w)
    net

let test_xor () =
  let net = Mlp.create [ 2; 4; 1 ] in
  Mlp.train ~epochs:2000 ~lr:0.5 net Data.xor;
  Alcotest.(check (float 0.)) "all four correct" 1. (Mlp.accuracy net Data.xor)

let test_circle () =
  let net = Mlp.create [ 2; 8; 1 ] in
  Mlp.train ~epochs:300 ~lr:0.1 net (Data.circle ~seed:7 400);
  Alcotest.(check bool) "generalizes to unseen points" true
    (Mlp.accuracy net (Data.circle ~seed:99 200) > 0.9)

let () =
  Alcotest.run "neural_network"
    [ ( "mlp",
        [ Alcotest.test_case "shapes" `Quick test_shapes;
          Alcotest.test_case "gradient check" `Quick test_gradient_check;
          Alcotest.test_case "learns xor" `Quick test_xor;
          Alcotest.test_case "learns circle" `Quick test_circle ] ) ]
