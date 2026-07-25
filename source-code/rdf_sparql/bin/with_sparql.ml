(* Parse a small subset of SPARQL text and run the queries. The Haskell version
   uses ReadP parser combinators; here we use a short recursive descent parser. *)

open Simple_rdf

exception Parse_error of string

let parse_query input =
  let n = String.length input in
  let pos = ref 0 in
  let is_space c = c = ' ' || c = '\t' || c = '\n' || c = '\r' in
  let is_alnum c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
  in
  let skip_spaces () =
    while !pos < n && is_space input.[!pos] do
      incr pos
    done
  in
  let peek () = if !pos < n then Some input.[!pos] else None in
  let expect c =
    if !pos < n && input.[!pos] = c then incr pos
    else raise (Parse_error (Printf.sprintf "expected '%c'" c))
  in
  let munch pred =
    let start = !pos in
    while !pos < n && pred input.[!pos] do
      incr pos
    done;
    String.sub input start (!pos - start)
  in
  let munch1 pred name =
    let s = munch pred in
    if s = "" then raise (Parse_error ("expected " ^ name)) else s
  in
  let keyword_ci kw =
    let len = String.length kw in
    if
      !pos + len <= n
      && String.lowercase_ascii (String.sub input !pos len)
         = String.lowercase_ascii kw
    then pos := !pos + len
    else raise (Parse_error ("expected " ^ kw))
  in
  let parse_var_name () =
    expect '?';
    munch1 is_alnum "variable name"
  in
  let parse_query_node () =
    match peek () with
    | Some '?' -> QVar (parse_var_name ())
    | Some '<' ->
        incr pos;
        let s = munch (fun c -> c <> '>') in
        expect '>';
        QTerm (IRI s)
    | Some '"' ->
        incr pos;
        let s = munch (fun c -> c <> '"') in
        expect '"';
        QTerm (Lit s)
    | _ -> QTerm (IRI (munch1 is_alnum "term"))
  in
  let parse_triple_pattern () =
    let s = parse_query_node () in
    skip_spaces ();
    let p = parse_query_node () in
    skip_spaces ();
    let o = parse_query_node () in
    TP (s, p, o)
  in
  try
    skip_spaces ();
    keyword_ci "SELECT";
    skip_spaces ();
    let vars = ref [] in
    while (match peek () with Some '?' -> true | _ -> false) do
      vars := parse_var_name () :: !vars;
      skip_spaces ()
    done;
    keyword_ci "WHERE";
    skip_spaces ();
    expect '{';
    skip_spaces ();
    let pats = ref [] in
    let continue = ref true in
    while !continue do
      skip_spaces ();
      match peek () with
      | Some '}' -> continue := false
      | None -> raise (Parse_error "unexpected end of input")
      | _ ->
          pats := parse_triple_pattern () :: !pats;
          skip_spaces ();
          if peek () = Some '.' then (
            incr pos;
            skip_spaces ())
    done;
    expect '}';
    Ok { vars = List.rev !vars; where_clause = List.rev !pats }
  with Parse_error msg -> Error msg

let iri s = IRI s
let lit s = Lit s

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

let run_and_print (desc, q_str) =
  Printf.printf "\n--- %s ---\n" desc;
  match parse_query q_str with
  | Error err -> Printf.printf "Error parsing query: %s\n" err
  | Ok q ->
      let results = run_query my_graph q in
      let headers = List.map (fun v -> "?" ^ v) q.vars in
      print_table headers results

let () =
  print_endline "--- RDF Store Loaded ---";
  List.iter (fun t -> print_endline (show_triple t)) my_graph;
  let queries =
    [
      ( "Query 1: Select ?s ?o where { ?s likes ?o }",
        "SELECT ?s ?o WHERE { ?s likes ?o }" );
      ( "Query 2: Select ?who where { ?who likes <Bob> }",
        "SELECT ?who WHERE { ?who likes <Bob> }" );
      ( "Query 3 (Join): Who likes someone who likes them back?",
        "SELECT ?a ?b WHERE { ?a likes ?b . ?b likes ?a }" );
    ]
  in
  List.iter run_and_print queries
