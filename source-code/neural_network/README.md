# Neural Network - OCaml

A multilayer perceptron trained with backpropagation, written with the standard
library and float arrays only. The demo trains one network on XOR and another
on points inside a circle, then prints an ASCII map of the learned region.

## Project layout

```
neural_network/
├── lib/mlp.ml    <- layers, forward pass, loss, backpropagation, SGD training
├── lib/data.ml   <- XOR and circle data sets
├── bin/main.ml   <- XOR and circle demos
└── test/         <- Alcotest suite, including a numerical gradient check
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes

- This example is new in the OCaml book; the Haskell book has no counterpart.
- Hidden layers use `tanh` and the output uses a sigmoid, trained on binary
  cross-entropy, so the output delta is simply `output - target`.
- Seeds are fixed, so every run prints the same numbers.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
