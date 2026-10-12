(* Toy data sets. Each example is (inputs, targets), both float arrays. *)

(* XOR is the classic problem a single layer cannot learn: no straight line
   separates the 1s from the 0s, so the network needs a hidden layer. *)
let xor =
  [ ([| 0.; 0. |], [| 0. |]);
    ([| 0.; 1. |], [| 1. |]);
    ([| 1.; 0. |], [| 1. |]);
    ([| 1.; 1. |], [| 0. |]) ]

let radius = 0.6

(* Random points in the square [-1, 1] x [-1, 1], labeled 1 when they fall
   inside a circle of [radius] around the origin. The boundary is a curve, so
   the network has to learn a nonlinear decision region. *)
let circle ?(seed = 7) n =
  let rng = Random.State.make [| seed |] in
  List.init n (fun _ ->
      let x = Random.State.float rng 2. -. 1. in
      let y = Random.State.float rng 2. -. 1. in
      let inside = (x *. x) +. (y *. y) < radius *. radius in
      ([| x; y |], [| (if inside then 1. else 0.) |]))
