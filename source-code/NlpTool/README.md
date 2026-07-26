# NLP Tool - OCaml

OCaml port of the Haskell NlpTool. A command-line natural-language tool that
categorizes text, summarizes it, and detects people, company, and country
names. It also includes a Porter stemmer and an abbreviation-aware sentence
segmenter.

## Project layout

```
NlpTool/
├── src/
│   ├── nlp_utils.ml   <- tokenization and n-grams
│   ├── stemmer.ml     <- Porter stemmer
│   ├── sentence.ml    <- sentence segmentation
│   ├── categorize.ml  <- category scoring
│   ├── entities.ml    <- name -> URI lookup
│   ├── summarize.ml   <- extractive summarization
│   └── nlp_data.ml    <- TSV corpus loaders
├── data/              <- generated TSV corpora (see below)
├── bin/main.ml        <- interactive tool
└── test/              <- Alcotest suite (no corpus needed)
```

## Generate the data

The Haskell version embedded the corpora as large `Map.fromList` literals (the
people list alone is 2.5 MB). Here the data lives in TSV files, generated once
from the Haskell sources:

```bash
python3 convert_data.py \
  /path/to/haskell_book/source-code/NlpTool/src/nlp/data
```

## Build and run

Run from the project root so `data/*.tsv` resolves:

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- The corpora move from embedded `Map` literals to TSV files loaded at startup,
  which keeps the OCaml small and fast to compile.
- The category and entity functions take the loaded data as arguments, so the
  unit tests run against tiny in-memory maps with no corpus.
- Two clear typos in the Haskell were corrected: `bigram_s` no longer repeats the
  first word, and the summarizer combines 1-gram and 2-gram scores (the original
  added the 1-gram scores to themselves). Both fixes make the two-word matching
  actually work.
- The Porter stemmer and the fullstop-style segmenter are ported faithfully.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
