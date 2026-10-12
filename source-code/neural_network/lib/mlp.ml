(* A multilayer perceptron with backpropagation, written from scratch with
   plain float arrays. Hidden layers use tanh; the output layer uses a sigmoid,
   so each output is a probability, and training minimizes binary
   cross-entropy. *)

(* One fully connected layer: w.(j).(i) is the weight from input i to unit j. *)
type layer = { w : float array array; b : float array }

(* A network is its layers in order, input side first. *)
type t = layer array

(* The gradient of the loss with respect to one layer's weights and biases. *)
type grad = { dw : float array array; db : float array }

let sigmoid x = 1. /. (1. +. exp (-.x))

(* [create [2; 8; 1]] builds a network with 2 inputs, one hidden layer of 8
   units, and 1 output. Weights start small and random (Glorot uniform), which
   breaks the symmetry between units; biases start at zero. *)
let create ?(seed = 42) sizes =
  let rng = Random.State.make [| seed |] in
  let layer n_in n_out =
    let limit = sqrt (6. /. float_of_int (n_in + n_out)) in
    { w =
        Array.init n_out (fun _ ->
            Array.init n_in (fun _ -> Random.State.float rng (2. *. limit) -. limit));
      b = Array.make n_out 0. }
  in
  let rec layers = function
    | n_in :: (n_out :: _ as rest) -> layer n_in n_out :: layers rest
    | _ -> []
  in
  if List.length sizes < 2 then invalid_arg "Mlp.create: need input and output sizes";
  Array.of_list (layers sizes)

(* z_j = b_j + sum_i w_ji * x_i for every unit j in the layer. *)
let affine l x =
  Array.mapi
    (fun j row ->
      let s = ref l.b.(j) in
      Array.iteri (fun i wi -> s := !s +. (wi *. x.(i))) row;
      !s)
    l.w

(* Run the network and keep every layer's output: acts.(0) is the input and
   acts.(n) is the network's output. Backpropagation needs them all. *)
let forward net x =
  let n = Array.length net in
  let acts = Array.make (n + 1) x in
  Array.iteri
    (fun k l ->
      let activation = if k = n - 1 then sigmoid else tanh in
      acts.(k + 1) <- Array.map activation (affine l acts.(k)))
    net;
  acts

let predict net x =
  let acts = forward net x in
  acts.(Array.length acts - 1)

(* Binary cross-entropy for one example. Clamping keeps log away from 0. *)
let example_loss net x target =
  let eps = 1e-12 in
  let out = predict net x in
  let total = ref 0. in
  Array.iteri
    (fun j t ->
      let p = Float.min (1. -. eps) (Float.max eps out.(j)) in
      total := !total -. ((t *. log p) +. ((1. -. t) *. log (1. -. p))))
    target;
  !total

let loss net data =
  List.fold_left (fun acc (x, t) -> acc +. example_loss net x t) 0. data
  /. float_of_int (List.length data)

(* Backpropagation for one example. [delta] holds dLoss/dz for the current
   layer. With a sigmoid output and cross-entropy loss it starts out as simply
   (output - target). Moving down a layer multiplies by the transposed weights
   and by tanh's derivative, 1 - a^2. *)
let backprop net x target =
  let acts = forward net x in
  let n = Array.length net in
  let grads = Array.make n { dw = [||]; db = [||] } in
  let delta = ref (Array.map2 (fun a t -> a -. t) acts.(n) target) in
  for k = n - 1 downto 0 do
    let l = net.(k) and input = acts.(k) and d = !delta in
    grads.(k) <-
      { dw = Array.map (fun dj -> Array.map (fun xi -> dj *. xi) input) d;
        db = Array.copy d };
    if k > 0 then
      delta :=
        Array.mapi
          (fun i a ->
            let s = ref 0. in
            Array.iteri (fun j dj -> s := !s +. (l.w.(j).(i) *. dj)) d;
            !s *. (1. -. (a *. a)))
          input
  done;
  grads

(* Gradient descent: move every weight a small step against its gradient. *)
let step net ~lr grads =
  Array.iteri
    (fun k g ->
      let l = net.(k) in
      Array.iteri
        (fun j row ->
          l.b.(j) <- l.b.(j) -. (lr *. g.db.(j));
          Array.iteri (fun i gi -> row.(i) <- row.(i) -. (lr *. gi)) g.dw.(j))
        l.w)
    grads

let shuffle rng a =
  for i = Array.length a - 1 downto 1 do
    let j = Random.State.int rng (i + 1) in
    let tmp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- tmp
  done

(* Stochastic gradient descent: each epoch visits the examples in a fresh
   random order and updates after every one. [on_epoch] lets the caller watch
   progress. *)
let train ?(seed = 1) ?(on_epoch = fun _ -> ()) ~epochs ~lr net data =
  let rng = Random.State.make [| seed |] in
  let examples = Array.of_list data in
  for epoch = 1 to epochs do
    shuffle rng examples;
    Array.iter (fun (x, t) -> step net ~lr (backprop net x t)) examples;
    on_epoch epoch
  done

(* Fraction of examples whose single output lands on the right side of 0.5. *)
let accuracy net data =
  let correct =
    List.length
      (List.filter (fun (x, t) -> (predict net x).(0) > 0.5 = (t.(0) > 0.5)) data)
  in
  float_of_int correct /. float_of_int (List.length data)
