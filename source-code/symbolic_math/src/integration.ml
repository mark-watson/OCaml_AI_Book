(* Symbolic integration of single-variable polynomials, plus definite
   integral evaluation via the Fundamental Theorem of Calculus. *)

open Types

(* Reverse power rule on one monomial. Integral c x^n dx = (c/(n+1)) x^(n+1).
   The constant of integration is handled by the caller. *)
let integrate_term t =
  let new_exp = t.term_exponent + 1 in
  let new_coef = Rational.div t.term_coefficient (Rational.of_int new_exp) in
  {
    term_coefficient = new_coef;
    term_variable = t.term_variable;
    term_exponent = new_exp;
  }

let integrate p =
  let new_terms = List.map integrate_term p.poly_terms in
  if new_terms = [] then zero_polynomial p.poly_variable
  else make_polynomial p.poly_variable new_terms p.poly_domain

let resolve_bound_to_float = function
  | BNum r -> Rational.to_float r
  | BConst c -> constant_numeric_value c

(* Integral[a,b] p dx = F(b) - F(a) where F = integrate p. *)
let evaluate_definite p lower upper =
  let f = integrate p in
  let a = resolve_bound_to_float lower in
  let b = resolve_bound_to_float upper in
  polynomial_evaluate f b -. polynomial_evaluate f a

let rec integrate_n p n =
  if n < 0 then failwith "integrate_n: n must be non-negative"
  else if n = 0 then p
  else integrate_n (integrate p) (n - 1)

let make_indefinite_integral p = make_integral p p.poly_variable None None

let make_definite_integral p lower upper =
  make_integral p p.poly_variable (Some lower) (Some upper)

let run_smoke_test () =
  let x = make_variable "x" Real in
  let pi_c = make_constant "pi" SymbolicPi in
  let r = Rational.of_int in
  let p =
    make_polynomial x
      [ make_term (r 3) x 2; make_term (r (-1)) x 1; make_term (r 5) x 0 ]
      Real
  in
  let ip = integrate p in
  let iip = integrate_n p 2 in
  let q =
    make_polynomial x [ make_term (r 6) x 1; make_term (r 2) x 0 ] Real
  in
  let iq = integrate q in
  let def01 = evaluate_definite p (BNum (r 0)) (BNum (r 1)) in
  let def_q01 = evaluate_definite q (BNum (r 0)) (BNum (r 1)) in
  let def_pi = evaluate_definite p (BNum (r 0)) (BConst pi_c) in
  let indef_shell = make_indefinite_integral p in
  let def_shell = make_definite_integral p (BNum (r 0)) (BNum (r 1)) in
  let pi_shell = make_definite_integral p (BNum (r 0)) (BConst pi_c) in
  print_newline ();
  print_endline "=== Integration Smoke Test ===";
  print_newline ();
  Printf.printf "p              : %s\n" (polynomial_to_string p);
  Printf.printf "int p dx       : %s\n" (polynomial_to_string ip);
  Printf.printf "int int p dx   : %s\n" (polynomial_to_string iip);
  print_newline ();
  Printf.printf "q              : %s\n" (polynomial_to_string q);
  Printf.printf "int q dx       : %s\n" (polynomial_to_string iq);
  print_newline ();
  Printf.printf "def [0,1] p dx : %g  (expected 5.5)\n" def01;
  Printf.printf "def [0,1] q dx : %g  (expected 5.0)\n" def_q01;
  Printf.printf "def [0,pi] p dx: %g\n" def_pi;
  print_newline ();
  Printf.printf "indef shell    : %s\n" (integral_to_string indef_shell);
  Printf.printf "def [0,1]      : %s\n" (integral_to_string def_shell);
  Printf.printf "def [0,pi]     : %s\n" (integral_to_string pi_shell);
  print_newline ();
  print_endline "=============================="
