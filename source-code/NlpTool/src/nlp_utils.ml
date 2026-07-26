(* Tokenization and n-gram helpers, ported from the Haskell NlpUtils module. *)

let is_space c = c = ' ' || c = '\t' || c = '\n' || c = '\r'
let is_digit c = c >= '0' && c <= '9'
let is_upper c = c >= 'A' && c <= 'Z'
let is_alpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

let replace_all sub by s =
  let sl = String.length sub in
  if sl = 0 then s
  else begin
    let buf = Buffer.create (String.length s) in
    let n = String.length s in
    let i = ref 0 in
    while !i < n do
      if !i + sl <= n && String.sub s !i sl = sub then begin
        Buffer.add_string buf by;
        i := !i + sl
      end
      else begin
        Buffer.add_char buf s.[!i];
        incr i
      end
    done;
    Buffer.contents buf
  end

(* Replace the curly quotes with straight ones (UTF-8 bytes spelled out). *)
let clean_text s =
  s
  |> replace_all "\xe2\x80\x9c" "\"" (* left double quote *)
  |> replace_all "\xe2\x80\x9d" "\"" (* right double quote *)
  |> replace_all "\xe2\x80\x99" "'"  (* right single quote *)

(* Split on whitespace, dropping empty pieces (Haskell `words`). *)
let words s =
  s |> String.split_on_char ' ' |> List.filter (fun w -> w <> "")

let map_punctuation ~lower s =
  String.map
    (fun c ->
      if String.contains ".,;:!\n\t\"" c then ' '
      else if lower then Char.lowercase_ascii c
      else c)
    s

let split_words s = words (map_punctuation ~lower:true s)
let split_words_keep_case s = words (map_punctuation ~lower:false s)

let rec bigram = function
  | a :: (b :: _ as rest) -> [ a; b ] :: bigram rest
  | _ -> []

let rec trigram = function
  | a :: (b :: c :: _ as rest) -> [ a; b; c ] :: trigram rest
  | _ -> []

(* Space-joined n-grams. The Haskell `bigram_s` had a typo that repeated the
   first word; here we join the actual pair so two-word names and category
   bigrams match as intended. *)
let bigram_s xs =
  List.filter_map (function [ a; b ] -> Some (a ^ " " ^ b) | _ -> None) (bigram xs)

let trigram_s xs =
  List.filter_map
    (function [ a; b; c ] -> Some (a ^ " " ^ b ^ " " ^ c) | _ -> None)
    (trigram xs)

let remove_duplicates xs = List.sort_uniq compare xs
