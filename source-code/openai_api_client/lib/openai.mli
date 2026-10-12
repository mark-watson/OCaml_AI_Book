val default_model : string
val chat_request_json : model:string -> prompt:string -> Yojson.Safe.t
val content_of_json : Yojson.Safe.t -> (string, string) result
val split_entities : string -> string list
