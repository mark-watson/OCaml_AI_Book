# Natural Language Processing

This chapter builds two natural language tools. The first, in `source-code/FastTag/`, is a part-of-speech tagger: it labels each word in a sentence as a noun, verb, adjective, and so on. The second, in `source-code/NlpTool/`, is a larger toolkit that categorizes text, summarizes it, and finds the names of people, companies, and countries. Both are rule-and-lexicon systems, not neural networks, so you can read every decision they make.

## A Part-of-Speech Tagger

FastTag is a simplified version of Eric Brill's tagger. It works in two passes. First it looks up a starting tag for each word in a lexicon. Then it applies a short list of transformation rules that fix the common cases the lexicon gets wrong.

The lexicon is a large table of word-to-tag pairs, embedded as one tab-separated record per line. The file `src/fasttag.ml` parses it into a `Hashtbl` once at startup:

```ocaml
let lexicon : (string, string) Hashtbl.t =
  let tbl = Hashtbl.create 131072 in
  List.iter
    (fun line ->
      match String.index_opt line '\t' with
      | Some i ->
          let word = String.sub line 0 i in
          let tag = String.sub line (i + 1) (String.length line - i - 1) in
          Hashtbl.replace tbl word tag
      | None -> ())
    (String.split_on_char '\n' Lexicon_data.data);
  tbl
```

A `Hashtbl` gives constant-time lookup, which matters because the lexicon holds tens of thousands of words. The starting tag for a word is its lexicon entry, or `NN` (a common noun) when the word is unknown:

```ocaml
let tag_helper token =
  match Hashtbl.find_opt lexicon token with
  | Some tag when tag <> "" -> [ token; tag ]
  | _ -> [ token; "NN" ]
```

The pattern `Some tag when tag <> ""` is a guarded case: it matches only when the found tag is non-empty. The rules need to see each word next to the one before it, so `substitute` builds a sliding window of pairs with `bigram`:

```ocaml
let rec bigram = function
  | [] | [ _ ] -> []
  | x :: (y :: _ as rest) -> [ x; y ] :: bigram rest
```

The pattern `y :: _ as rest` binds `y` to the second element and `rest` to the whole tail at once, so each step keeps a word and looks ahead to the next.

### The Transformation Rules

The heart of the tagger is `fix_tags`. For each `[previous; current]` pair it decides whether to change the current word's tag. The rules read like a checklist:

```ocaml
let starts p = String.starts_with ~prefix:p cur_tag in
let ends s = String.ends_with ~suffix:s cur_tok in
let first_is_n = String.length cur_tag > 0 && cur_tag.[0] = 'N' in
(* rule 1: DT, {VBD | VB | VBP} -> DT, NN *)
if last_tag = "DT" && (cur_tag = "VBD" || cur_tag = "VB" || cur_tag = "VBP")
then "NN"
  (* rule 3: noun -> past participle if the word ends with "ed" *)
else if first_is_n && ends "ed" then "VBN"
  (* rule 4: any type -> adverb if it ends in "ly" *)
else if ends "ly" then "RB"
  (* rule 7: common noun -> plural common noun if it ends with "s" *)
else if starts "NN" && ends "s" then "NNS"
  ...
else cur_tag
```

Each rule fixes one common mistake. Rule 1 says a word after "the" is a noun, not a verb, so "the run" tags "run" as a noun. Rule 4 says a word ending in "ly" is an adverb. When no rule fires, the word keeps its lexicon tag. Tagging a sentence chains the passes, with an empty token prepended so the first real word has a predecessor:

```ocaml
let tag tokens = fix_tags (substitute ("" :: tokens))
```

Run the demo on a sample sentence:

```bash
cd source-code/FastTag
dune build
dune exec ./bin/main.exe
```

It prints each word paired with its tag: determiners as `DT`, nouns as `NN`, past-tense verbs as `VBD`, and so on. The whole tagger is under 75 lines plus the data, and it shows how far a lexicon and a handful of rules can go.

## An NLP Toolkit

The `NlpTool` example is a set of modules that share a small foundation. The command-line program loads its data, then categorizes, summarizes, and extracts names from whatever you type. The modules live under one library named `Nlp`.

### Tokenizing and N-grams

The file `src/nlp_utils.ml` handles the basics: clean curly quotes, split into words, and build n-grams. Two functions split text, one lower-casing and one keeping case (names need their capitals):

```ocaml
let split_words s = words (map_punctuation ~lower:true s)
let split_words_keep_case s = words (map_punctuation ~lower:false s)
```

N-grams are runs of two or three neighboring words. The list versions slide a window; the string versions join each run with a space, so a bigram becomes one lookup key:

```ocaml
let bigram_s xs =
  List.filter_map (function [ a; b ] -> Some (a ^ " " ^ b) | _ -> None) (bigram xs)
```

These joined n-grams are how the toolkit matches two-word categories and two-word names.

### Stemming

The file `src/stemmer.ml` is a full Porter stemmer, which reduces a word to its root: "running", "runs", and "ran" all relate back to "run". Its public function is `Stemmer.stem : string -> string`. The categorizer stems both the input and its word lists so that different forms of a word still match. The algorithm is a fixed sequence of suffix-stripping steps; the code ports it step for step, and you call it without needing to know the internals.

### Sentence Segmentation

Splitting text into sentences is harder than splitting on periods, because a period also ends an abbreviation, a title, an initial, or a decimal number. The file `src/sentence.ml` handles this in two stages. First `breakup` cuts the text into chunks, each ending in a run of `.`, `?`, or `!`:

```ocaml
let breakup s =
  let n = String.length s in
  let segs = ref [] and buf = Buffer.create 32 in
  let i = ref 0 in
  while !i < n do
    let c = s.[!i] in
    Buffer.add_char buf c;
    if is_term c then begin
      incr i;
      while !i < n && is_term s.[!i] do
        Buffer.add_char buf s.[!i];
        incr i
      done;
      segs := Buffer.contents buf :: !segs;
      Buffer.clear buf
    end
    else incr i
  done;
  ...
```

Then `squish` glues chunks back together when the break was a false alarm. It runs several passes, each merging a chunk with its neighbor when a test says the split was wrong:

```ocaml
let squish lst =
  lst
  |> squish_by (fun x y -> ends_with_digit x && starts_with_digit y)
  |> squish_by (fun x _ -> ends_with_any x titles)
  |> squish_by (fun x _ -> looks_like_initial (ltrim x))
  |> squish_by (fun _ y -> not (starts_with_space y))
  |> squish_by (fun x _ -> ends_with_any x abbreviations)
```

Each `squish_by` pass takes a test between a chunk and the next. The tests catch decimals like "3.14", titles like "Dr.", single-letter initials, and known abbreviations, and rejoin the pieces those periods split. The result is a clean list of sentences.

### Loading the Data

The corpora live in tab-separated files, loaded at startup by `src/nlp_data.ml`. An entity map is a name-to-URI table; the category data is a list of category names, each with a word-to-score table:

```ocaml
let load_entity_map path : (string, string) Hashtbl.t =
  let tbl = Hashtbl.create 1024 in
  List.iter
    (fun line ->
      match String.split_on_char '\t' line with
      | [ name; uri ] -> Hashtbl.replace tbl name uri
      | _ -> ())
    (read_lines path);
  tbl
```

Keeping the data in files, rather than embedded in the source, keeps the OCaml small and quick to compile. Because the loaders take a path and return a table, the functions that use them take the table as an argument, which makes them easy to test against a tiny in-memory map.

### Categorizing Text

The file `src/categorize.ml` scores text against the category word lists. Scoring one category sums the scores of the words that appear in its table:

```ocaml
let score_cat words (m : (string, float) Hashtbl.t) =
  List.fold_left
    (fun acc w -> acc +. Option.value ~default:0. (Hashtbl.find_opt m w))
    0. words
```

`best_categories` scores against four tables, the raw and stemmed 1-gram and 2-gram lists, merges the scores, and normalizes them to probabilities:

```ocaml
let best_categories ~onegrams ~twograms words =
  let stem1 = stem_ngrams onegrams and stem2 = stem_ngrams twograms in
  let bigrams = Nlp_utils.bigram_s words in
  let b1 = take 3 (best_categories_helper words onegrams) in
  let b2 = take 3 (best_categories_helper bigrams twograms) in
  ...
  let total = List.fold_left (fun a (_, v) -> a +. v) 0. non_normalized in
  List.map
    (fun (name, v) -> (name, if total = 0. then 0. else v /. total))
    non_normalized
```

Combining single words with two-word phrases, in both raw and stemmed form, makes the categorizer robust: "health care" scores as a phrase, and "running" matches "run".

### Finding Names

The file `src/entities.ml` detects names by looking up 1-, 2-, and 3-grams of the case-preserving words in an entity map:

```ocaml
let entity_names (entity_map : (string, string) Hashtbl.t) words =
  let ngrams =
    words @ Nlp_utils.bigram_s words @ Nlp_utils.trigram_s words
  in
  ngrams
  |> List.filter_map (fun ng ->
         match Hashtbl.find_opt entity_map ng with
         | Some uri -> Some (ng, uri)
         | None -> None)
  |> List.sort_uniq compare
```

It joins the single words, the bigrams, and the trigrams into one list, keeps the runs that match a name, and returns each name with its URI. Using three sizes of n-gram catches "IBM", "United States", and "New York City" alike.

### Summarizing

The file `src/summarize.ml` picks the sentences that best fit the document's top categories. It scores each sentence by how well its words match the best categories, then keeps the two highest scorers:

```ocaml
let score_for_sentence words (cat_maps : Nlp_data.ngrams) best_cats =
  List.fold_left
    (fun acc (cat, m) ->
      acc +. (safe_lookup cat best_cats *. score_sentence_helper words m))
    0. cat_maps
```

A sentence scores high when its words belong to the categories the whole document is about. The final step, `cascade`, lowers a threshold step by step until exactly two sentences clear it, which gives a two-sentence summary:

```ocaml
let rec cascade = function
  | t :: rest ->
    let c = tier t in
    if exactly_two c then c else cascade rest
  | [] -> ...
in
cascade [ 10.; 7.; 4.; 3.; 2.; 1.; 0.5 ]
```

### The Command-Line Tool

The program in `bin/main.ml` ties it together. It loads the corpora, then loops: read a line, categorize it, summarize it, and list the people, companies, and countries it names:

```ocaml
let cats = Categorize.best_categories ~onegrams ~twograms (Nlp_utils.split_words s) in
let best_cat = match cats with (name, _) :: _ -> name | [] -> "" in
let spwkc = Nlp_utils.split_words_keep_case s in
Printf.printf "category:\t%s\n" best_cat;
Printf.printf "summary:\t%s\n" (Summarize.summarize_s ~onegrams ~twograms s);
Printf.printf "people:\t%s\n" (show_entities (Entities.entity_names people spwkc));
```

Note that categorization uses lower-cased words, while entity detection uses `split_words_keep_case` so names keep their capitals. Run it from the project root so the data files resolve:

```bash
cd source-code/NlpTool
dune build
dune exec ./bin/main.exe
dune runtest
```

Type a paragraph and the tool prints its category, a short summary, and any names it finds. The tests run against tiny in-memory maps, so they need no corpus. This same toolkit powers the knowledge graph builder in Chapter 14, which turns these categories, entities, and summaries into graph data.
