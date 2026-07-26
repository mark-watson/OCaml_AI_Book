val gemini_request : string -> Yojson.Safe.t
val text_of_json : Yojson.Safe.t -> (string, string) result
val prompt_of_body : string -> string
val page : string
