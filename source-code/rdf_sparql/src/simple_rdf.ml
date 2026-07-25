(* In-memory RDF store and a small SPARQL-style query engine. *)

(* A node is an IRI, a literal string, or a blank node. *)
type node = IRI of string | Lit of string | BNode of int

(* N-Triples style display. *)
let format_node = function
  | IRI s -> "<" ^ s ^ ">"
  | Lit s -> "\"" ^ s ^ "\""
  | BNode i -> "_:b" ^ string_of_int i

type triple = node * node * node
type graph = triple list

(* A query item is a concrete node or a variable such as ?x. *)
type query_node = QTerm of node | QVar of string

(* A triple pattern such as { ?s <likes> ?o }. *)
type triple_pattern = TP of query_node * query_node * query_node

type select_query = { vars : string list; where_clause : triple_pattern list }

module StringMap = Map.Make (String)

(* A binding maps variable names to concrete nodes. *)
type binding = node StringMap.t

(* Match one query node against a concrete node under the current binding. *)
let match_node ctx qn n =
  match qn with
  | QTerm t -> if t = n then Some ctx else None
  | QVar v -> (
      match StringMap.find_opt v ctx with
      | None -> Some (StringMap.add v n ctx)
      | Some value -> if value = n then Some ctx else None)

(* Match a whole triple pattern, threading the binding through each position. *)
let match_triple ctx (TP (qs, qp, qo)) (s, p, o) =
  match match_node ctx qs s with
  | None -> None
  | Some ctx1 -> (
      match match_node ctx1 qp p with
      | None -> None
      | Some ctx2 -> match_node ctx2 qo o)

(* Evaluate a list of patterns against the graph. Haskell uses the list monad
   for the backtracking join; here List.concat_map plays the same role. *)
let rec evaluate_patterns graph = function
  | [] -> [ StringMap.empty ]
  | pat :: pats ->
      List.concat_map
        (fun ctx -> List.filter_map (fun triple -> match_triple ctx pat triple) graph)
        (evaluate_patterns graph pats)

(* Order-preserving duplicate removal, matching Haskell's nub. *)
let nub lst =
  let rec go seen = function
    | [] -> []
    | x :: xs -> if List.mem x seen then go seen xs else x :: go (x :: seen) xs
  in
  go [] lst

let run_query graph query =
  let all_bindings = evaluate_patterns graph (List.rev query.where_clause) in
  let project binding =
    List.map
      (fun v ->
        match StringMap.find_opt v binding with Some n -> n | None -> Lit "NULL")
      query.vars
  in
  nub (List.map project all_bindings)
