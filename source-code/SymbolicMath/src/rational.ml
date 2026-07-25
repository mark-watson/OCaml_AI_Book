(* A small exact rational number type. OCaml has no built-in Rational,
   so coefficients in the symbolic math layer use this module. Values are
   always stored normalized: denominator positive, gcd(|num|, den) = 1. *)

type t = { num : int; den : int }

let rec gcd a b = if b = 0 then a else gcd b (a mod b)

let make num den =
  if den = 0 then failwith "Rational.make: zero denominator";
  let sign = if den < 0 then -1 else 1 in
  let num = num * sign and den = den * sign in
  let g = gcd (abs num) den in
  let g = if g = 0 then 1 else g in
  { num = num / g; den = den / g }

let of_int n = { num = n; den = 1 }
let zero = of_int 0
let one = of_int 1

let add a b = make ((a.num * b.den) + (b.num * a.den)) (a.den * b.den)
let sub a b = make ((a.num * b.den) - (b.num * a.den)) (a.den * b.den)
let mul a b = make (a.num * b.num) (a.den * b.den)
let div a b = make (a.num * b.den) (a.den * b.num)
let neg a = { num = -a.num; den = a.den }

let to_float a = float_of_int a.num /. float_of_int a.den
let is_zero a = a.num = 0
let equal a b = a.num = b.num && a.den = b.den
let compare a b = Stdlib.compare (a.num * b.den) (b.num * a.den)

(* Show a whole number without the "/1" suffix. *)
let to_string a =
  if a.den = 1 then string_of_int a.num
  else string_of_int a.num ^ "/" ^ string_of_int a.den
