(* Sentence segmentation, ported from the Haskell Sentence module (derived from
   Eric Kow's fullstop package). It splits on . ? ! but rejoins chunks split by
   abbreviations, titles, initials, and decimal numbers. *)

open Nlp_utils

let titles = [ "Mr."; "Mrs."; "Dr."; "St." ]

let abbreviations =
  [ "A."; "Adj."; "Adm."; "Adv."; "Asst."; "B."; "Bart."; "Bldg."; "Brig.";
    "Bros."; "C."; "Capt."; "Cmdr."; "Col."; "Comdr."; "Con."; "Cpl."; "D.";
    "DR."; "Dr."; "E."; "Ens."; "F."; "G."; "Gen."; "Gov."; "H."; "Hon.";
    "Hosp."; "I."; "Insp."; "J."; "K."; "L."; "Lt."; "M."; "MM."; "MR."; "MRS.";
    "MS."; "Maj."; "Messrs."; "Mlle."; "Mme."; "Mr."; "Mrs."; "Ms."; "Msgr.";
    "N."; "O."; "Op."; "Ord."; "P."; "Pfc."; "Ph."; "Prof."; "Pvt."; "Q."; "R.";
    "Rep."; "Reps."; "Rev."; "S."; "Sen."; "Sens."; "Sfc."; "Sgt."; "Sr."; "St.";
    "Supt."; "T."; "U."; "V."; "W."; "X."; "Y."; "Z."; "v."; "vs."; "cf."; "eg.";
    "ie."; "i.e."; "e.g." ]

let is_term c = c = '.' || c = '?' || c = '!'

(* Break into chunks, each ending with a maximal run of terminators. *)
let breakup s =
  let n = String.length s in
  let segs = ref [] and buf = Buffer.create 32 in
  let i = ref 0 in
  while !i < n do
    let c = s.[!i] in
    Buffer.add_char buf c;
    if is_term c then begin
      incr i;
      while !i < n && is_term s.[!i] do
        Buffer.add_char buf s.[!i];
        incr i
      done;
      segs := Buffer.contents buf :: !segs;
      Buffer.clear buf
    end
    else incr i
  done;
  if Buffer.length buf > 0 then segs := Buffer.contents buf :: !segs;
  List.rev !segs

let is_word_suffix_of sub s =
  String.ends_with ~suffix:sub s
  &&
  let k = String.length s - String.length sub in
  k = 0 || not (is_alpha s.[k - 1])

let ends_with_any s subs = List.exists (fun sub -> is_word_suffix_of sub s) subs

let ltrim s =
  let n = String.length s in
  let i = ref 0 in
  while !i < n && is_space s.[!i] do incr i done;
  String.sub s !i (n - !i)

let looks_like_initial x =
  let n = String.length x in
  n >= 2 && x.[n - 1] = '.'
  && ((n = 2 && is_upper x.[n - 2])
     || (n >= 3 && is_upper x.[n - 2] && is_space x.[n - 3]))

let starts_with_space y = y <> "" && is_space y.[0]
let starts_with_digit y = y <> "" && is_digit y.[0]

let ends_with_digit x =
  let n = String.length x in
  n >= 2 && x.[n - 1] = '.' && is_digit x.[n - 2]

(* Merge each chunk with its right neighbour while [eq] holds. *)
let squish_by eq = function
  | [] -> []
  | x0 :: xs ->
    let assemble acc x0 = List.rev (x0 :: acc) in
    let rec helper acc x0 = function
      | [] -> [ assemble acc x0 ]
      | x1 :: rest ->
        if eq x0 x1 then helper (x0 :: acc) x1 rest
        else assemble acc x0 :: helper [] x1 rest
    in
    List.map (String.concat "") (helper [] x0 xs)

let squish lst =
  lst
  |> squish_by (fun x y -> ends_with_digit x && starts_with_digit y)
  |> squish_by (fun x _ -> ends_with_any x titles)
  |> squish_by (fun x _ -> looks_like_initial (ltrim x))
  |> squish_by (fun _ y -> not (starts_with_space y))
  |> squish_by (fun x _ -> ends_with_any x abbreviations)

let segment s = List.map ltrim (squish (breakup s))
