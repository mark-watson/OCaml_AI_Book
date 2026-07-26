# Knowledge Graph Creator

This chapter builds a tool that reads plain text and writes a knowledge graph. For each document it detects the people, companies, countries, and other entities the text names, works out what topics the text is about, summarizes it, and writes all of that as graph data in two formats: RDF triples for the semantic web, and Neo4j Cypher for a graph database. The example is in `source-code/knowledge_graph_creator/`, and it is the capstone of the book: it reuses the NLP toolkit from Chapter 7 and the RDF ideas from Chapter 9.

## The Pipeline

The tool works on a directory of `.txt` files. Each text file has a matching `.meta` file, a small JSON file that gives the document's URI. For each document the tool runs the NLP toolkit to find entities, categories, and a summary, then turns those into triples and Cypher. The library that ties it together is named `Kg`.

## Reading Input

The file `src/file_utils.ml` reads the text and parses the `.meta` file. A meta file holds a URI and a list of similar documents, parsed with Yojson:

```ocaml
type my_meta = { uri : string; similar_docs : string list }

let read_meta_file path =
  let json = Yojson.Safe.from_string (read_file path) in
  let open Yojson.Safe.Util in
  {
    uri = json |> member "uri" |> to_string;
    similar_docs =
      (match json |> member "similar_docs" with
       | `List xs -> List.filter_map (function `String s -> Some s | _ -> None) xs
       | _ -> []);
  }
```

The document's URI becomes the subject of every triple the tool writes about that document. The entity data lives in eight name-to-URI tables, one per entity kind, held in a record:

```ocaml
type entity_maps = {
  people : (string, string) Hashtbl.t;
  companies : (string, string) Hashtbl.t;
  countries : (string, string) Hashtbl.t;
  cities : (string, string) Hashtbl.t;
  broadcast_networks : (string, string) Hashtbl.t;
  political_parties : (string, string) Hashtbl.t;
  trade_unions : (string, string) Hashtbl.t;
  universities : (string, string) Hashtbl.t;
}
```

`load_entity_maps` loads all eight from their TSV files. Grouping them in a record means the generators take one `emaps` argument instead of eight.

## Generating RDF Triples

The file `src/gen_triples.ml` writes RDF in N3 form. A triple is a subject, a predicate, and an object, ending in a period, which is exactly what `generate_triple` builds:

```ocaml
let generate_triple s p o = s ^ "  " ^ p ^ "  " ^ o ^ " .\n"
let make_literal s = "\"" ^ s ^ "\""
let schema s = "<http://knowledgebooks.com/schema/" ^ s ^ ">"
```

For each entity kind, the tool writes two kinds of triple: a "contains" triple saying the document mentions an entity, and an "about" triple giving the entity's name. The `entity_block` helper produces both for one entity map:

```ocaml
let entity_block contains_pred about_pred m =
  let pairs = names m in
  contains contains_pred pairs ^ about about_pred pairs
```

`names m` is `Entities.entity_names m word_tokens`, the entity detector from Chapter 7 run against one of the eight maps. Categories become triples too, but only the strong ones. The categorizer returns each topic with a score, and the tool keeps those above 0.3, mapping each to a topic URI:

```ocaml
let category_triples =
  cats
  |> List.filter (fun (_n, v) -> v > 0.3)
  |> List.map (fun (n, _) ->
         generate_triple subj (schema "news/category/") (uri_from_category n))
  |> String.concat ""
```

`uri_from_category` looks up the topic in a table that maps category names to knowledge-base URIs, so "computers_ai_nlp" becomes a proper resource. Finally, the summarizer from Chapter 7 produces a one-line summary, written as a single triple. The whole document turns into one block of triples: entity links, entity names, category links, and a summary.

## Generating Neo4j Cypher

The file `src/gen_neo4j_cypher.ml` writes the same information as Cypher, the query language for the Neo4j graph database. Where RDF writes triples, Cypher writes `CREATE` statements for nodes and relationships:

```ocaml
let create_neo4j_link node1 link_name node2 =
  Printf.sprintf "CREATE (%s)-[:%s]->(%s)\n" node1 link_name node2

let create_entity_node (name, uri) =
  Printf.sprintf "CREATE (%s:Entity {name:\"%s\", uri:\"%s\"})\n"
    (Nlp_utils.replace_all " " "_" name)
    name uri
```

Cypher node names cannot contain arbitrary characters, so the code cleans them first. `filter_chars` drops characters like `?` and `<`, and `repl` turns `-`, `/`, and `.` into underscores:

```ocaml
let repl = function '-' | '/' | '.' -> '_' | c -> c

let filter_chars s =
  String.to_seq s
  |> Seq.filter (fun c -> c <> '?' && c <> '=' && c <> '<' && c <> '>')
  |> String.of_seq
```

`String.to_seq` and `String.of_seq` convert a string to and from a lazy sequence of characters, so you can `Seq.filter` it like any other sequence. The generator writes a node for the document, a summary node, a category link per strong topic, and, for each entity, an entity node plus a relationship from the document to it. The result is a Cypher script you can load straight into Neo4j.

## Batch Processing

The file `src/apis.ml` runs the generators over a whole directory. It lists the text files, pairs each with its `.meta` file, generates output for each, and writes one combined file:

```ocaml
let meta_of txt = Filename.remove_extension txt ^ ".meta"

let process_files_to_rdf ~onegrams ~twograms ~emaps dir out =
  list_text_files dir
  |> List.map (fun fp ->
         Gen_triples.text_to_triples ~onegrams ~twograms ~emaps fp (meta_of fp))
  |> String.concat ""
  |> write_file out
```

`meta_of` swaps the `.txt` extension for `.meta` with `Filename.remove_extension`, so each text file finds its metadata. The pipeline maps the generator over every file and concatenates the output. The Cypher version is the same shape, with a block of category-node definitions added at the top.

## Running It

The program in `bin/main.ml` takes an input directory and an output name, loads the corpora, and writes both formats:

```ocaml
let () =
  match Array.to_list Sys.argv with
  | [ _; input_dir; output_root ] ->
    let onegrams = Nlp_data.load_ngrams "data/category_1gram.tsv" in
    let twograms = Nlp_data.load_ngrams "data/category_2gram.tsv" in
    let emaps = File_utils.load_entity_maps "data" in
    Apis.process_files_to_rdf ~onegrams ~twograms ~emaps input_dir
      (output_root ^ ".n3");
    Apis.process_files_to_neo4j ~onegrams ~twograms ~emaps input_dir
      (output_root ^ ".cypher");
    ...
```

Run it from the project root so the data directory resolves, pointing it at the sample input:

```bash
cd source-code/knowledge_graph_creator
dune build
dune exec ./bin/main.exe -- test_data out
dune runtest
```

That reads the `.txt` and `.meta` files in `test_data/`, then writes `out.n3` and `out.cypher`. Open the `.n3` file and you see triples linking the document to the people, companies, and topics it mentions, plus a summary. Open the `.cypher` file and you see the same graph as `CREATE` statements. This tool shows the payoff of the earlier chapters: the NLP toolkit finds the facts, and a few string builders turn them into two standard graph formats, ready to load into a triple store or Neo4j.
