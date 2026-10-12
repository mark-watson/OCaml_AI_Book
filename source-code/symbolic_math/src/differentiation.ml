(* Symbolic differentiation of single-variable polynomials. *)

open Types

(* Power rule on one monomial. d/dx(c x^n) = n c x^(n-1); constants give None. *)
let differentiate_term t =
  if t.term_exponent = 0 then None
  else
    Some
      {
        term_coefficient =
          Rational.mul (Rational.of_int t.term_exponent) t.term_coefficient;
        term_variable = t.term_variable;
        term_exponent = t.term_exponent - 1;
      }

let differentiate p =
  let diff_terms = List.filter_map differentiate_term p.poly_terms in
  if diff_terms = [] then zero_polynomial p.poly_variable
  else make_polynomial p.poly_variable diff_terms p.poly_domain

let rec differentiate_n p n =
  if n < 0 then failwith "differentiate_n: n must be non-negative"
  else if n = 0 then p
  else differentiate_n (differentiate p) (n - 1)

let gradient_at p x = polynomial_evaluate (differentiate p) x

let critical_point_p p x tolerance = Float.abs (gradient_at p x) < tolerance

let run_smoke_test () =
  let x = make_variable "x" Real in
  let r = Rational.of_int in
  let p =
    make_polynomial x
      [ make_term (r 3) x 2; make_term (r (-1)) x 1; make_term (r 5) x 0 ]
      Real
  in
  let dp = differentiate p in
  let ddp = differentiate dp in
  let dddp = differentiate ddp in
  let q =
    make_polynomial x
      [ make_term (r 1) x 4; make_term (r (-2)) x 3; make_term (r 1) x 1 ]
      Real
  in
  let dq = differentiate q in
  let ddq = differentiate_n q 2 in
  let cp = 1.0 /. 6.0 in
  print_newline ();
  print_endline "=== Differentiation Smoke Test ===";
  print_newline ();
  Printf.printf "p            : %s\n" (polynomial_to_string p);
  Printf.printf "p'           : %s\n" (polynomial_to_string dp);
  Printf.printf "p''          : %s\n" (polynomial_to_string ddp);
  Printf.printf "p'''         : %s\n" (polynomial_to_string dddp);
  print_newline ();
  Printf.printf "q            : %s\n" (polynomial_to_string q);
  Printf.printf "q'           : %s\n" (polynomial_to_string dq);
  Printf.printf "q'' (via n=2): %s\n" (polynomial_to_string ddq);
  print_newline ();
  Printf.printf "gradient-at(p, 0)      : %g  (expected -1)\n" (gradient_at p 0.0);
  Printf.printf "gradient-at(p, 1)      : %g  (expected  5)\n" (gradient_at p 1.0);
  Printf.printf "critical-point-p(p,1/6): %b  (expected true)\n"
    (critical_point_p p cp 1e-9);
  Printf.printf "critical-point-p(p,0)  : %b  (expected false)\n"
    (critical_point_p p 0.0 1e-9);
  print_newline ();
  print_endline "=================================="
