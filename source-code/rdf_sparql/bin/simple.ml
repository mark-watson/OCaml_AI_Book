(* Load a small social network graph and run queries built directly as data. *)

open Simple_rdf

let iri s = IRI s
let lit s = Lit s

(* Haskell derived Show for a triple, used to echo the loaded store. *)
let show_node = function
  | IRI s -> Printf.sprintf "IRI %S" s
  | Lit s -> Printf.sprintf "Lit %S" s
  | BNode i -> Printf.sprintf "BNode %d" i

let show_triple (s, p, o) =
  Printf.sprintf "(%s,%s,%s)" (show_node s) (show_node p) (show_node o)

let my_graph =
  [
    (iri "Alice", iri "likes", iri "Bob");
    (iri "Alice", iri "likes", iri "Pizza");
    (iri "Bob", iri "likes", iri "Alice");
    (iri "Bob", iri "likes", iri "Pasta");
    (iri "Charlie", iri "likes", iri "Bob");
    (iri "Alice", iri "age", lit "25");
    (iri "Bob", iri "age", lit "28");
  ]

let print_table headers rows =
  let hdr = String.concat " " headers in
  print_endline hdr;
  print_endline (String.make (String.length hdr + 5) '-');
  List.iter
    (fun row -> print_endline (String.concat " " (List.map format_node row)))
    rows

let () =
  print_endline "--- RDF Store Loaded ---";
  List.iter (fun t -> print_endline (show_triple t)) my_graph;

  print_endline "\n--- Query 1: Select ?s ?o where { ?s likes ?o } ---";
  let q1 =
    {
      vars = [ "s"; "o" ];
      where_clause = [ TP (QVar "s", QTerm (iri "likes"), QVar "o") ];
    }
  in
  print_table [ "?s"; "?o" ] (run_query my_graph q1);

  print_endline "\n--- Query 2: Select ?who where { ?who likes <Bob> } ---";
  let q2 =
    {
      vars = [ "who" ];
      where_clause = [ TP (QVar "who", QTerm (iri "likes"), QTerm (iri "Bob")) ];
    }
  in
  print_table [ "?who" ] (run_query my_graph q2);

  print_endline "\n--- Query 3 (Join): Who likes someone who likes them back? ---";
  let q3 =
    {
      vars = [ "a"; "b" ];
      where_clause =
        [
          TP (QVar "a", QTerm (iri "likes"), QVar "b");
          TP (QVar "b", QTerm (iri "likes"), QVar "a");
        ];
    }
  in
  print_table [ "?a"; "?b" ] (run_query my_graph q3)
