val dbpedia : string

(* Build a query URL. [format] defaults to "json". *)
val query_uri : ?endpoint:string -> ?format:string -> string -> Uri.t

(* Values bound to [var] in every row of a SPARQL JSON result set. *)
val values_of_json : string -> Yojson.Safe.t -> string list
