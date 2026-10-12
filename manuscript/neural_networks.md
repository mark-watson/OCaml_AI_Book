# Neural Networks from Scratch

The other AI chapters in this book use rules, lexicons, search, and hosted models. This chapter trains a neural network. It builds a multilayer perceptron, the basic network type of deep learning, with nothing but OCaml's standard library and float arrays. There is no matrix library and no automatic differentiation: every step of training fits in 140 lines. The code is in `source-code/neural_network/`.

Libraries such as Owl and ocaml-torch do this faster and scale to large models. For learning how a network trains, a small version you can read line by line works better, and it uses the same build-it-yourself approach as the RDF store and the knowledge graph builder earlier in the book.

## The Network

A network is a stack of **layers**. Each layer takes a vector of inputs and produces a vector of outputs, one per **unit**. A unit computes a weighted sum of its inputs, adds a bias, and passes the result through an **activation function**:

```ocaml
type layer = { w : float array array; b : float array }

type t = layer array
```

`w.(j).(i)` is the weight from input `i` to unit `j`, and `b.(j)` is unit `j`'s bias. The weights and biases are the network's parameters, the numbers that training adjusts. The arrays are mutable, so training updates them in place.

`create` takes a list of layer sizes. `create [2; 8; 1]` builds a network with 2 inputs, a hidden layer of 8 units, and 1 output:

```ocaml
let create ?(seed = 42) sizes =
  let rng = Random.State.make [| seed |] in
  let layer n_in n_out =
    let limit = sqrt (6. /. float_of_int (n_in + n_out)) in
    { w =
        Array.init n_out (fun _ ->
            Array.init n_in (fun _ -> Random.State.float rng (2. *. limit) -. limit));
      b = Array.make n_out 0. }
  in
  ...
```

The weights start as small random numbers. If every weight started equal, every unit in a layer would compute the same thing and receive the same update, and the units would never differ. The range `sqrt (6 / (n_in + n_out))` is Glorot initialization. It keeps the size of the signals roughly constant from layer to layer, so training starts in a useful range. A fixed seed makes every run give the same result, which the tests rely on.

## The Forward Pass

Running the network on an input is the **forward pass**. Each layer computes `z = W x + b`, applies its activation, and hands the result to the next layer:

```ocaml
let affine l x =
  Array.mapi
    (fun j row ->
      let s = ref l.b.(j) in
      Array.iteri (fun i wi -> s := !s +. (wi *. x.(i))) row;
      !s)
    l.w

let forward net x =
  let n = Array.length net in
  let acts = Array.make (n + 1) x in
  Array.iteri
    (fun k l ->
      let activation = if k = n - 1 then sigmoid else tanh in
      acts.(k + 1) <- Array.map activation (affine l acts.(k)))
    net;
  acts
```

Hidden layers use `tanh`, which maps any number into the range -1 to 1. The output layer uses the sigmoid, `1 / (1 + e^(-x))`, which maps into 0 to 1, so the output reads as a probability: "how sure is the network that this input is a 1?"

The activations make the network more than a linear function. Without them, a stack of layers would collapse into a single matrix multiply, and no number of layers could learn a curved boundary.

`forward` returns every layer's output, not only the last one. `acts.(0)` is the input and `acts.(n)` is the output. Training needs all of them. `predict` is the forward pass with only the last entry kept.

## Measuring Error

Training needs a number that says how wrong the network is. For a probability output and a 0 or 1 target, the standard choice is **binary cross-entropy**:

```ocaml
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
```

When the target is 1 the loss is `-log p`, which is near 0 when `p` is near 1 and grows without limit as `p` falls toward 0. A target of 0 works the same way with `1 - p`. A confident wrong answer costs far more than an unsure one. The clamp keeps `log` away from 0. `loss` averages `example_loss` over a data set.

## Backpropagation

Training lowers the loss by **gradient descent**. For each parameter, compute the gradient: how much the loss changes when that parameter changes a little. Then move every parameter a small step in the direction that lowers the loss. **Backpropagation** is the algorithm that computes all the gradients in one backward pass through the network, using the chain rule from calculus.

The quantity it tracks is `delta`, the gradient of the loss with respect to each unit's weighted sum `z`. At the output layer, the sigmoid and cross-entropy derivatives cancel to give a simple result: `delta = output - target`. That is one reason the two get used together.

Given a layer's `delta`, two things follow:

1. The gradient for weight `w.(j).(i)` is `delta.(j) *. input.(i)`, where `input` is what the layer received in the forward pass. The bias gradient is `delta.(j)` itself.
2. The `delta` for the layer below is the current `delta` sent back through the transposed weights, then multiplied by the derivative of `tanh`. For an output `a = tanh z`, that derivative is `1 - a * a`, so the code never needs `z`.

The code follows those two steps from the top layer down:

```ocaml
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
```

`backprop` only computes gradients; it changes nothing. A separate `step` subtracts `lr` times each gradient from its parameter, where `lr`, the **learning rate**, sets the step size. Keeping the two apart makes the gradients easy to test, as you will see below.

## Training

`train` runs **stochastic gradient descent**. Each **epoch** shuffles the examples and takes one step per example:

```ocaml
let train ?(seed = 1) ?(on_epoch = fun _ -> ()) ~epochs ~lr net data =
  let rng = Random.State.make [| seed |] in
  let examples = Array.of_list data in
  for epoch = 1 to epochs do
    shuffle rng examples;
    Array.iter (fun (x, t) -> step net ~lr (backprop net x t)) examples;
    on_epoch epoch
  done
```

The shuffle matters. Without it the network sees the same order every epoch and can cycle through the same updates. The optional `on_epoch` callback lets the caller print progress without the training loop knowing about printing.

## Learning XOR

XOR is the classic first test. It outputs 1 when exactly one input is 1. No straight line separates the 1s from the 0s, so a network with no hidden layer cannot learn it. That limit, shown by Minsky and Papert in 1969, slowed neural network research for over a decade. One hidden layer fixes it:

```ocaml
let net = Mlp.create [ 2; 4; 1 ] in
Mlp.train ~epochs:2000 ~lr:0.5 net Data.xor;
```

The demo prints:

```
== XOR: 2 inputs, 4 hidden units, 1 output ==
loss before training: 0.6955
loss after training:  0.0006
  0 xor 0 -> 0.000 (target 0)
  0 xor 1 -> 0.999 (target 1)
  1 xor 0 -> 0.999 (target 1)
  1 xor 1 -> 0.001 (target 0)
```

The starting loss of 0.6955 is close to `log 2`, the loss of a network that answers 0.5 to everything. After training, all four outputs are close to their targets.

## A Curved Boundary

XOR has only four examples, so the network can memorize them. A better test asks the network to **generalize**: to learn from some examples and then label new ones it has never seen. `Data.circle` makes random points in the square from -1 to 1, labeled 1 inside a circle of radius 0.6 and 0 outside. The demo trains on 400 points, then scores the network on 200 new ones from a different seed:

```ocaml
let train = Data.circle ~seed:7 400 and test = Data.circle ~seed:99 200 in
let net = Mlp.create [ 2; 8; 1 ] in
Mlp.train ~epochs:300 ~lr:0.1 net train ~on_epoch:(fun e ->
    if e mod 50 = 0 then
      Printf.printf "epoch %3d  training loss %.4f\n" e (Mlp.loss net train));
```

The output:

```
epoch  50  training loss 0.1358
epoch 100  training loss 0.0659
epoch 150  training loss 0.0717
epoch 200  training loss 0.0657
epoch 250  training loss 0.0287
epoch 300  training loss 0.0322
accuracy on training data: 98.2%
accuracy on unseen data:   99.0%
```

The loss does not fall every epoch. Each step follows the gradient of a single example, which can push the total loss up a little, but the trend runs down. Accuracy on unseen data matches accuracy on the training data, so the network learned the shape and did not just memorize the points.

To see what it learned, the demo asks the network about a grid of points across the square and prints `#` where it answers "inside":

```
.........................................
.........................................
.........................................
.........................................
.........................................
..............##############.............
............##################...........
...........####################..........
..........######################.........
.........#######################.........
........#########################........
........########################.........
........########################.........
.........######################..........
..........####################...........
.............#############...............
.........................................
```

(I cut a few rows of dots from the bottom.) Each column steps 0.05 and each row steps 0.1, which makes up for terminal characters being about twice as tall as they are wide, so the circle prints close to round. Eight `tanh` units, each a soft straight-line boundary, combine into a closed curve. That ability to build complex boundaries out of simple units is what a hidden layer gives you.

## Testing a Network

Neural network bugs rarely crash. A sign error in backpropagation gives a network that trains badly, and it can take a long time to notice. The standard defense is a **gradient check**: estimate each gradient with finite differences and compare it with what `backprop` computed. Nudge a weight up by a tiny `h`, measure the loss, nudge it down, measure again, and the slope `(up - down) / 2h` approximates the true gradient:

```ocaml
row.(i) <- w +. h;
let up = Mlp.example_loss net x t in
row.(i) <- w -. h;
let down = Mlp.example_loss net x t in
row.(i) <- w;
let numeric = (up -. down) /. (2. *. h) in
Alcotest.(check (float 1e-6)) "dw" numeric grads.(k).dw.(j).(i)
```

The test runs this check over every weight in a small network. Keeping `backprop` separate from `step` makes it possible: the test gets the gradients without the network changing under it. The other tests check layer shapes, that XOR gets all four cases right, and that the circle network scores over 90% on unseen points. They all run in under a tenth of a second:

```bash
cd source-code/neural_network
dune exec ./bin/main.exe
dune runtest
```

## Where to Go Next

This network trains one example at a time with plain loops, which is fine for toy problems and slow for real ones. Real libraries do the same math on whole batches as matrix operations, often on a GPU, and compute gradients with automatic differentiation instead of by hand. The ideas in this chapter carry over unchanged: forward pass, loss, backpropagation, gradient descent, and checking the gradients.

Some ways to extend the code:

- Add a second hidden layer with `create [2; 8; 8; 1]`. The code already handles any depth.
- Replace `tanh` with ReLU, `max 0 x`, the default in modern deep networks, and change the derivative in `backprop` to match.
- Train on mini-batches: average the gradients of several examples before each `step`.
- Train on the iris or MNIST data sets with the CSV reader from Chapter 6.

For larger models in OCaml, look at [Owl](https://ocaml.xyz/) for numerical computing and [ocaml-torch](https://github.com/LaurentMazare/ocaml-torch) for bindings to PyTorch's tensor library.
