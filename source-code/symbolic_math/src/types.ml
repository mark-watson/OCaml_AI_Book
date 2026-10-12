(* Core data structures for the symbolic math layer:
   domains, variables, constants, monomial terms, polynomials, and integrals. *)

(* 1. Domain *)
type domain = Real | Complex | Integer_

(* 2. Variable *)
type variable = { var_name : string; var_domain : domain }

let make_variable name domain = { var_name = name; var_domain = domain }
let variable_eq a b = a.var_name = b.var_name && a.var_domain = b.var_domain

(* 3. Constant *)
type constant_value = ExactValue of Rational.t | SymbolicPi | SymbolicE
type constant = { const_name : string; const_value : constant_value }

let make_constant name value = { const_name = name; const_value = value }

let constant_numeric_value c =
  match c.const_value with
  | SymbolicPi -> Float.pi
  | SymbolicE -> exp 1.0
  | ExactValue r -> Rational.to_float r

(* 4. Term: coefficient * variable ^ exponent *)
type term = {
  term_coefficient : Rational.t;
  term_variable : variable;
  term_exponent : int;
}

let make_term coeff var exp_ =
  if exp_ < 0 then failwith "make_term: exponent must be non-negative"
  else { term_coefficient = coeff; term_variable = var; term_exponent = exp_ }

let term_eq a b =
  Rational.equal a.term_coefficient b.term_coefficient
  && variable_eq a.term_variable b.term_variable
  && a.term_exponent = b.term_exponent

let term_negate t = { t with term_coefficient = Rational.neg t.term_coefficient }

let term_scale s t =
  { t with term_coefficient = Rational.mul s t.term_coefficient }

let term_to_string t =
  let name = t.term_variable.var_name in
  let c = Rational.to_string t.term_coefficient in
  if t.term_exponent = 0 then c
  else if t.term_exponent = 1 then c ^ name
  else c ^ name ^ "^" ^ string_of_int t.term_exponent

(* 5. Polynomial: ordered terms in descending exponent *)
type polynomial = {
  poly_variable : variable;
  poly_terms : term list;
  poly_domain : domain;
}

(* Combine like exponents, drop zero coefficients, sort descending. *)
let make_polynomial var terms domain =
  let tbl = Hashtbl.create 16 in
  List.iter
    (fun t ->
      let e = t.term_exponent in
      let c =
        match Hashtbl.find_opt tbl e with
        | Some prev -> Rational.add prev t.term_coefficient
        | None -> t.term_coefficient
      in
      Hashtbl.replace tbl e c)
    terms;
  let pairs =
    Hashtbl.fold
      (fun e c acc -> if Rational.is_zero c then acc else (e, c) :: acc)
      tbl []
  in
  let sorted = List.sort (fun (e1, _) (e2, _) -> compare e2 e1) pairs in
  let new_terms =
    List.map
      (fun (e, c) ->
        { term_coefficient = c; term_variable = var; term_exponent = e })
      sorted
  in
  { poly_variable = var; poly_terms = new_terms; poly_domain = domain }

let polynomial_normalize p =
  make_polynomial p.poly_variable p.poly_terms p.poly_domain

let polynomial_degree p =
  match p.poly_terms with [] -> -1 | t :: _ -> t.term_exponent

let polynomial_leading_term p =
  match p.poly_terms with [] -> None | t :: _ -> Some t

let polynomial_add p q =
  if not (variable_eq p.poly_variable q.poly_variable) then
    failwith
      (Printf.sprintf "Cannot add polynomials in different variables: %s and %s"
         p.poly_variable.var_name q.poly_variable.var_name)
  else
    make_polynomial p.poly_variable (p.poly_terms @ q.poly_terms) p.poly_domain

let polynomial_negate p =
  make_polynomial p.poly_variable (List.map term_negate p.poly_terms)
    p.poly_domain

let polynomial_subtract p q = polynomial_add p (polynomial_negate q)

let polynomial_scale s p =
  make_polynomial p.poly_variable
    (List.map (term_scale s) p.poly_terms)
    p.poly_domain

let rec rat_pow r n = if n <= 0 then Rational.one else Rational.mul r (rat_pow r (n - 1))

let float_pow x n =
  let r = ref 1.0 in
  for _ = 1 to n do
    r := !r *. x
  done;
  !r

(* Exact evaluation over rationals. *)
let polynomial_evaluate_q p x =
  List.fold_left
    (fun acc t ->
      Rational.add acc (Rational.mul t.term_coefficient (rat_pow x t.term_exponent)))
    Rational.zero p.poly_terms

(* Numeric evaluation over floats (used by gradient and definite integrals). *)
let polynomial_evaluate p x =
  List.fold_left
    (fun acc t ->
      acc +. (Rational.to_float t.term_coefficient *. float_pow x t.term_exponent))
    0.0 p.poly_terms

let polynomial_to_string p =
  match p.poly_terms with
  | [] -> "0"
  | terms -> String.concat " + " (List.map term_to_string terms)

let zero_polynomial var =
  { poly_variable = var; poly_terms = []; poly_domain = Real }

let constant_polynomial var value =
  make_polynomial var [ make_term value var 0 ] Real

let identity_polynomial var =
  make_polynomial var [ make_term Rational.one var 1 ] Real

(* 6. SymIntegral: a definite or indefinite integral. A bound is either an
   exact number or a named constant (the OCaml form of Either Rational Constant). *)
type bound = BNum of Rational.t | BConst of constant

type sym_integral = {
  integrand : polynomial;
  int_variable : variable;
  int_lower : bound option;
  int_upper : bound option;
}

let make_integral integrand var lower upper =
  match (lower, upper) with
  | Some _, None | None, Some _ ->
      failwith "make_integral: either both bounds or neither must be provided"
  | _ ->
      { integrand; int_variable = var; int_lower = lower; int_upper = upper }

let integral_definite_p i = match i.int_lower with Some _ -> true | None -> false

let bound_to_string = function
  | BNum r -> Rational.to_string r
  | BConst c -> c.const_name

let integral_to_string i =
  let var_str = i.int_variable.var_name in
  let body = polynomial_to_string i.integrand in
  let bounds_str =
    match (i.int_lower, i.int_upper) with
    | Some l, Some h ->
        "[" ^ bound_to_string l ^ "," ^ bound_to_string h ^ "]"
    | _ -> ""
  in
  "\xe2\x88\xab" ^ bounds_str ^ "(" ^ body ^ ") d" ^ var_str

(* 7. Smoke test *)
let run_smoke_test () =
  let x = make_variable "x" Real in
  let pi_const = make_constant "pi" SymbolicPi in
  let r = Rational.of_int in
  let p =
    make_polynomial x
      [ make_term (r 3) x 2; make_term (r (-1)) x 1; make_term (r 5) x 0 ]
      Real
  in
  let q =
    make_polynomial x [ make_term (r 1) x 1; make_term (r 2) x 0 ] Real
  in
  let sum_pq = polynomial_add p q in
  let diff_pq = polynomial_subtract p q in
  let scaled = polynomial_scale (r 2) p in
  let indef = make_integral p x None None in
  let def01 = make_integral p x (Some (BNum (r 0))) (Some (BNum (r 1))) in
  let pi_int = make_integral p x (Some (BNum (r 0))) (Some (BConst pi_const)) in
  print_newline ();
  print_endline "=== Symbolic Math Data Layer Smoke Test ===";
  print_newline ();
  Printf.printf "p         : %s\n" (polynomial_to_string p);
  Printf.printf "q         : %s\n" (polynomial_to_string q);
  Printf.printf "p + q     : %s\n" (polynomial_to_string sum_pq);
  Printf.printf "p - q     : %s\n" (polynomial_to_string diff_pq);
  Printf.printf "2 * p     : %s\n" (polynomial_to_string scaled);
  Printf.printf "degree(p) : %d\n" (polynomial_degree p);
  Printf.printf "p(0)      : %s\n" (Rational.to_string (polynomial_evaluate_q p (r 0)));
  Printf.printf "p(1)      : %s\n" (Rational.to_string (polynomial_evaluate_q p (r 1)));
  Printf.printf "p(2)      : %s\n" (Rational.to_string (polynomial_evaluate_q p (r 2)));
  Printf.printf "indef     : %s\n" (integral_to_string indef);
  Printf.printf "def       : %s\n" (integral_to_string def01);
  Printf.printf "pi-int    : %s\n" (integral_to_string pi_int);
  print_newline ();
  print_endline "==========================================="
