(* Collapse all visible text nodes into one whitespace-separated string. *)
val extract_texts : string -> string

(* Collect the href of every <a> tag. *)
val extract_links : string -> string list
