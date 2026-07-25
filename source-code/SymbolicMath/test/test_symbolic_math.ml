(* Alcotest port of the original HSpec suite. *)

open Symbolic_math
open Types

let x = make_variable "x" Real
let r = Rational.of_int

let test_term () =
  Alcotest.(check string)
    "termToString renders a monomial" "3x^2"
    (term_to_string (make_term (r 3) x 2));
  Alcotest.(check string)
    "termToString renders constant term" "5"
    (term_to_string (make_term (r 5) x 0));
  Alcotest.(check bool)
    "termNegate negates the coefficient" true
    (term_eq (term_negate (make_term (r 3) x 2)) (make_term (r (-3)) x 2));
  Alcotest.(check bool)
    "termScale scales the coefficient" true
    (term_eq (term_scale (r 2) (make_term (r 3) x 2)) (make_term (r 6) x 2))

let test_polynomial () =
  let p =
    make_polynomial x
      [ make_term (r 3) x 2; make_term (r (-1)) x 1; make_term (r 5) x 0 ]
      Real
  in
  Alcotest.(check int) "degree returns highest exponent" 2 (polynomial_degree p);
  Alcotest.(check int)
    "degree returns -1 for zero polynomial" (-1)
    (polynomial_degree (zero_polynomial x));
  let p1 = make_polynomial x [ make_term (r 1) x 1; make_term (r 2) x 0 ] Real in
  let q1 = make_polynomial x [ make_term (r 3) x 1; make_term (r 4) x 0 ] Real in
  Alcotest.(check string)
    "add combines like terms" "4x + 6"
    (polynomial_to_string (polynomial_add p1 q1));
  let p2 = make_polynomial x [ make_term (r 5) x 1 ] Real in
  let q2 = make_polynomial x [ make_term (r 3) x 1 ] Real in
  Alcotest.(check string)
    "subtract subtracts correctly" "2x"
    (polynomial_to_string (polynomial_subtract p2 q2));
  Alcotest.(check (float 1e-9))
    "evaluate computes value" 15.0
    (polynomial_evaluate p 2.0);
  let p3 = make_polynomial x [ make_term (r 3) x 2; make_term (r (-1)) x 1 ] Real in
  Alcotest.(check string)
    "negate negates all terms" "-3x^2 + 1x"
    (polynomial_to_string (polynomial_negate p3));
  Alcotest.(check string)
    "zeroPolynomial renders as 0" "0"
    (polynomial_to_string (zero_polynomial x));
  Alcotest.(check string)
    "identityPolynomial is 1x" "1x"
    (polynomial_to_string (identity_polynomial x))

let test_differentiation () =
  Alcotest.(check bool)
    "differentiateTerm applies power rule" true
    (match Differentiation.differentiate_term (make_term (r 3) x 2) with
     | Some t -> term_eq t (make_term (r 6) x 1)
     | None -> false);
  Alcotest.(check bool)
    "differentiateTerm of constant returns None" true
    (Differentiation.differentiate_term (make_term (r 5) x 0) = None);
  let p =
    make_polynomial x
      [ make_term (r 3) x 2; make_term (r (-1)) x 1; make_term (r 5) x 0 ]
      Real
  in
  Alcotest.(check string)
    "differentiate computes derivative" "6x + -1"
    (polynomial_to_string (Differentiation.differentiate p));
  Alcotest.(check int)
    "differentiate of constant is zero polynomial" (-1)
    (polynomial_degree (Differentiation.differentiate (constant_polynomial x (r 7))));
  let p2 = make_polynomial x [ make_term (r 1) x 3 ] Real in
  Alcotest.(check string)
    "differentiateN twice gives second derivative" "6x"
    (polynomial_to_string (Differentiation.differentiate_n p2 2));
  Alcotest.(check (float 1e-9))
    "gradientAt computes numerical gradient" 11.0
    (Differentiation.gradient_at p 2.0);
  let p3 = make_polynomial x [ make_term (r 3) x 2; make_term (r (-1)) x 1 ] Real in
  Alcotest.(check bool)
    "criticalPointP identifies critical points" true
    (Differentiation.critical_point_p p3 (1.0 /. 6.0) 1e-9)

let test_integration () =
  let t = Integration.integrate_term (make_term (r 3) x 2) in
  Alcotest.(check bool)
    "integrateTerm coefficient is 1" true
    (Rational.equal t.term_coefficient (r 1));
  Alcotest.(check int) "integrateTerm exponent is 3" 3 t.term_exponent;
  let p = make_polynomial x [ make_term (r 3) x 2 ] Real in
  Alcotest.(check string)
    "integrate computes antiderivative" "1x^3"
    (polynomial_to_string (Integration.integrate p));
  let p2 = make_polynomial x [ make_term (r 6) x 1 ] Real in
  Alcotest.(check string)
    "integrateN twice gives double antiderivative" "1x^3"
    (polynomial_to_string (Integration.integrate_n p2 2));
  let p3 = make_polynomial x [ make_term (r 6) x 1; make_term (r 2) x 0 ] Real in
  Alcotest.(check (float 1e-9))
    "evaluateDefinite computes a definite integral" 5.0
    (Integration.evaluate_definite p3 (BNum (r 0)) (BNum (r 1)))

let () =
  Alcotest.run "SymbolicMath"
    [
      ("Term", [ Alcotest.test_case "term" `Quick test_term ]);
      ("Polynomial", [ Alcotest.test_case "polynomial" `Quick test_polynomial ]);
      ( "Differentiation",
        [ Alcotest.test_case "differentiation" `Quick test_differentiation ] );
      ("Integration", [ Alcotest.test_case "integration" `Quick test_integration ]);
    ]
