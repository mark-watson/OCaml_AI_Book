(* Train two small networks from scratch: one on XOR, one on points inside a
   circle. Prints the loss as training runs, the final accuracy, and an ASCII
   map of what the circle network learned. *)

open Nn

let xor_demo () =
  print_endline "== XOR: 2 inputs, 4 hidden units, 1 output ==";
  let net = Mlp.create [ 2; 4; 1 ] in
  Printf.printf "loss before training: %.4f\n" (Mlp.loss net Data.xor);
  Mlp.train ~epochs:2000 ~lr:0.5 net Data.xor;
  Printf.printf "loss after training:  %.4f\n" (Mlp.loss net Data.xor);
  List.iter
    (fun (x, t) ->
      Printf.printf "  %.0f xor %.0f -> %.3f (target %.0f)\n" x.(0) x.(1)
        (Mlp.predict net x).(0) t.(0))
    Data.xor

(* Sample the trained network on a grid over the input square: '#' where it
   says "inside", '.' where it says "outside". *)
let print_decision_map net =
  for row = 0 to 20 do
    let y = 1. -. (float_of_int row /. 10.) in
    for col = 0 to 40 do
      let x = (float_of_int col /. 20.) -. 1. in
      print_char (if (Mlp.predict net [| x; y |]).(0) > 0.5 then '#' else '.')
    done;
    print_newline ()
  done

let circle_demo () =
  print_endline "\n== Circle: 2 inputs, 8 hidden units, 1 output ==";
  let train = Data.circle ~seed:7 400 and test = Data.circle ~seed:99 200 in
  let net = Mlp.create [ 2; 8; 1 ] in
  Mlp.train ~epochs:300 ~lr:0.1 net train ~on_epoch:(fun e ->
      if e mod 50 = 0 then
        Printf.printf "epoch %3d  training loss %.4f\n" e (Mlp.loss net train));
  Printf.printf "accuracy on training data: %.1f%%\n" (100. *. Mlp.accuracy net train);
  Printf.printf "accuracy on unseen data:   %.1f%%\n" (100. *. Mlp.accuracy net test);
  print_endline "decision map ('#' = inside):";
  print_decision_map net

let () =
  xor_demo ();
  circle_demo ()
