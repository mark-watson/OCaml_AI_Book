(* Encode and decode a record to and from JSON with Yojson. This covers both
   the Haskell TestAESON (aeson) and TestTextJSON (Text.JSON) examples, which
   did the same round trip. *)

type person = { name : string; email : string }

let person_to_json p =
  `Assoc [ ("name", `String p.name); ("email", `String p.email) ]

let person_of_json j =
  let open Yojson.Safe.Util in
  { name = j |> member "name" |> to_string; email = j |> member "email" |> to_string }

let () =
  let a = Yojson.Safe.to_string (person_to_json { name = "Sam"; email = "sam@a.com" }) in
  Printf.printf "%S\n" a;
  match
    try Some (person_of_json (Yojson.Safe.from_string a)) with _ -> None
  with
  | None -> print_endline "Error: failed to decode JSON back to Person"
  | Some d ->
      Printf.printf "{name = %S; email = %S}\n" d.name d.email;
      print_endline d.name;
      print_endline d.email
