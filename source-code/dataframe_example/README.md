# DataFrame Example - OCaml

OCaml port of the Haskell `dataframe` example. It loads the California housing
dataset and shows load, summary statistics, derived columns, filtering,
selection, sorting, and group-and-aggregate.

## Project layout

```
dataframe_example/
├── src/dataframe.ml  <- a small string-cell dataframe over the csv library
├── bin/main.ml       <- the housing analysis
├── data/housing.csv  <- 50-row California housing sample
└── test/             <- Alcotest over derive/filter/group/sort
```

## Build and run

Run from the project root so `./data/housing.csv` resolves:

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

The program writes `./data/housing_enriched.csv`; `make clean` removes it.

## Notes on the Haskell to OCaml port

- The Haskell `dataframe` library has no direct OCaml equivalent in the standard
  stack (`owl` is not assumed here), so `dataframe.ml` implements a small,
  string-cell dataframe on top of the `csv` library.
- `D.derive` takes an accessor `g` that reads a column as a float, standing in
  for `F.col @Int "total_rooms"`; typed helpers `filter_float` and
  `filter_string` replace `F.col @Double`/`@Text` filters.
- `D.groupBy |> D.aggregate` becomes `group_by ~key ~aggs` with `Count` and
  `Mean` aggregators.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
