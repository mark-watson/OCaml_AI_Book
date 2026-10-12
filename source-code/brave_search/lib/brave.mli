type web_result = {
  type_ : string;
  index : int option;
  all : bool option;
  title : string option;
  url : string option;
  description : string option;
}

val web_result_of_json : Yojson.Safe.t -> web_result
val format_result : web_result -> string
val suggestions_of_json : Yojson.Safe.t -> string list
