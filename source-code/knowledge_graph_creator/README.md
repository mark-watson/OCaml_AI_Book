# Knowledge Graph Creator - OCaml

OCaml port of the Haskell KGCreator. It reads a directory of `.txt` files (each
with a matching `.meta` JSON file) and generates a knowledge graph as RDF
triples (`.n3`) and Neo4j Cypher (`.cypher`). It reuses the NLP toolkit from the
`nlp_tool` example for entity detection, categorization, and summarization.

## Project layout

```
knowledge_graph_creator/
├── src/
│   ├── nlp_utils.ml, stemmer.ml, sentence.ml,
│   ├── categorize.ml, entities.ml, summarize.ml, nlp_data.ml  <- NLP toolkit
│   ├── file_utils.ml         <- read text, parse .meta, load corpora
│   ├── gen_triples.ml        <- RDF (N3) generation
│   ├── gen_neo4j_cypher.ml   <- Neo4j Cypher generation
│   └── apis.ml               <- batch directory processing
├── data/                     <- TSV corpora (copied from nlp_tool)
├── test_data/                <- sample.txt and sample.meta
├── bin/main.ml
└── test/
```

## Build and run

Run from the project root so `./data` resolves:

```bash
dune build
dune exec ./bin/main.exe -- test_data out
dune runtest
```

This writes `out.n3` and `out.cypher`. `make clean` removes them.

## Notes on the Haskell to OCaml port

- The NLP modules and TSV corpora are shared with the `nlp_tool` example (the
  Haskell version likewise kept its own copies).
- `.meta` files are parsed with Yojson rather than `Text.JSON.Generic`.
- The RDF and Cypher generators are direct string builders, matching the Haskell
  `GenTriples` and `GenNeo4jCypher` modules.
- SQLite (unused in the Haskell `Apis`) is dropped.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
