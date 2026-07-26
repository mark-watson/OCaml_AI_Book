val request_json :
  ?temperature:float -> ?max_output_tokens:int -> string -> Yojson.Safe.t

val text_of_json : Yojson.Safe.t -> (string, string) result
val split_entities : string -> string list
