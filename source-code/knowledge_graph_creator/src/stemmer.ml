(* Porter stemmer, ported from the functional Haskell implementation
   (originally by Dmitry Antonyuk). *)

let rec is_consonant str i =
  match str.[i] with
  | 'a' | 'e' | 'i' | 'o' | 'u' -> false
  | 'y' -> i = 0 || not (is_consonant str (i - 1))
  | _ -> true

let is_vowel str i = not (is_consonant str i)

(* Number of vowel-consonant sequences (the Porter "measure"). *)
let measure word =
  let n = String.length word in
  let pattern = List.init n (fun i -> is_consonant word i) in
  let rec dedupe = function
    | a :: (b :: _ as rest) -> if a = b then dedupe rest else a :: dedupe rest
    | xs -> xs
  in
  let runs = true :: dedupe pattern in
  let without_last =
    match List.rev runs with [] -> [] | _ :: tl -> List.rev tl
  in
  List.length (List.filter (fun b -> not b) without_last)

let contains_vowel word =
  let n = String.length word in
  let rec go i = i < n && (is_vowel word i || go (i + 1)) in
  go 0

let ends_with_double word =
  let n = String.length word in
  n >= 2 && word.[n - 1] = word.[n - 2] && not (String.contains "aeiou" word.[n - 1])

let cvc word =
  let n = String.length word in
  n >= 3 && is_consonant word (n - 1) && is_vowel word (n - 2)
  && is_consonant word (n - 3)
  && not (String.contains "wxy" word.[n - 1])

type repl = Changed of string | Unchanged of string

let stateful_replace pred str suffix replacement =
  if String.ends_with ~suffix str then
    let part = String.sub str 0 (String.length str - String.length suffix) in
    Some (if pred part then Changed (part ^ replacement) else Unchanged str)
  else None

let replace_end pred str suffix replacement =
  Option.map
    (function Changed s | Unchanged s -> s)
    (stateful_replace pred str suffix replacement)

let rec find_stem pred word = function
  | [] -> None
  | (suffix, replacement) :: tl -> (
    match replace_end pred word suffix replacement with
    | Some s -> Some s
    | None -> find_stem pred word tl)

let measure_gt n str = measure str > n

let step1a word =
  Option.value ~default:word
    (find_stem (fun _ -> true) word
       [ ("sses", "ss"); ("ies", "i"); ("ss", "ss"); ("s", "") ])

type before = Done of string | Continue of string

let before_step1b word =
  match replace_end (measure_gt 0) word "eed" "ee" with
  | Some s -> Done s
  | None ->
    let try_suffix suf =
      match stateful_replace contains_vowel word suf "" with
      | Some (Changed s) -> Some s
      | _ -> None
    in
    (match try_suffix "ed" with
     | Some s -> Continue s
     | None -> (
       match try_suffix "ing" with Some s -> Continue s | None -> Done word))

let after_step1b word =
  let n = String.length word in
  let double =
    ends_with_double word && not (n > 0 && String.contains "lsz" word.[n - 1])
  in
  let m_eq1_cvc = measure word = 1 && cvc word in
  match
    find_stem (fun _ -> true) word [ ("at", "ate"); ("bl", "ble"); ("iz", "ize") ]
  with
  | Some s -> s
  | None ->
    if double then String.sub word 0 (n - 1)
    else if m_eq1_cvc then word ^ "e"
    else word

let step1b word =
  match before_step1b word with Done s -> s | Continue s -> after_step1b s

let step1c word = Option.value ~default:word (replace_end contains_vowel word "y" "i")
let step1 word = step1c (step1b (step1a word))

let step2 word =
  Option.value ~default:word
    (find_stem (measure_gt 0) word
       [ ("ational", "ate"); ("tional", "tion"); ("enci", "ence");
         ("anci", "ance"); ("izer", "ize"); ("bli", "ble"); ("alli", "al");
         ("entli", "ent"); ("eli", "e"); ("ousli", "ous"); ("ization", "ize");
         ("ation", "ate"); ("ator", "ate"); ("alism", "al"); ("iveness", "ive");
         ("fulness", "ful"); ("ousness", "ous"); ("aliti", "al");
         ("iviti", "ive"); ("biliti", "ble"); ("logi", "log") ])

let step3 word =
  Option.value ~default:word
    (find_stem (measure_gt 0) word
       [ ("icate", "ic"); ("ative", ""); ("alize", "al"); ("iciti", "ic");
         ("ical", "ic"); ("ful", ""); ("ness", "") ])

let step4 word =
  let find_gt1 suffixes = find_stem (measure_gt 1) word (List.map (fun s -> (s, "")) suffixes) in
  let gt1_and_st str =
    measure_gt 1 str
    && String.length str > 0
    && String.contains "st" str.[String.length str - 1]
  in
  match
    find_gt1
      [ "al"; "ance"; "ence"; "er"; "ic"; "able"; "ible"; "ant"; "ement";
        "ment"; "ent" ]
  with
  | Some s -> s
  | None -> (
    match find_stem gt1_and_st word [ ("ion", "") ] with
    | Some s -> s
    | None ->
      Option.value ~default:word
        (find_gt1 [ "ou"; "ism"; "ate"; "iti"; "ous"; "ive"; "ize" ]))

let step5a word =
  let test str = measure_gt 1 str || (measure str = 1 && not (cvc str)) in
  Option.value ~default:word (replace_end test word "e" "")

let step5b word =
  let cond s =
    String.length s > 0 && s.[String.length s - 1] = 'l' && measure_gt 1 s
  in
  Option.value ~default:word (replace_end cond word "l" "")

let stem word =
  if String.length word < 3 then word
  else word |> step1 |> step2 |> step3 |> step4 |> step5a |> step5b
