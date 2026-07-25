type ollama_request = {
  model : string;
  prompt : string;
  stream : bool;
}

type ollama_response = {
  resp_model : string;
  resp_created_at : string;
  resp_response : string;
  resp_done : bool;
  resp_done_reason : string option;
}

type ollama_error = {
  err_msg : string;
}

val request_to_yojson : ollama_request -> Yojson.Safe.t
val response_of_yojson : Yojson.Safe.t -> (ollama_response, string) result
val error_of_yojson : Yojson.Safe.t -> (ollama_error, string) result
