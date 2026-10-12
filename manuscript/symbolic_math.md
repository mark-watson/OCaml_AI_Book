# Symbolic Mathematics

This chapter builds a small computer algebra library. It works with single-variable polynomials as data, not as floating-point approximations, so it can differentiate and integrate them exactly and print the result as algebra. The code lives in `source-code/symbolic_math/` and splits into four modules: exact rationals, the data model, differentiation, and integration.

Symbolic math is a good showcase for OCaml. Variant types model the shapes a mathematical object can take, records group the fields, and pattern matching pulls them apart. The result reads close to the math it describes.

## Exact Rationals

Coefficients here are exact fractions, not floats, so `1/3` stays `1/3` and never drifts. OCaml has no built-in rational type, so `src/rational.ml` supplies one. A rational is a record of a numerator and denominator, always kept in lowest terms with a positive denominator:

```ocaml
type t = { num : int; den : int }

let rec gcd a b = if b = 0 then a else gcd b (a mod b)

let make num den =
  if den = 0 then failwith "Rational.make: zero denominator";
  let sign = if den < 0 then -1 else 1 in
  let num = num * sign and den = den * sign in
  let g = gcd (abs num) den in
  let g = if g = 0 then 1 else g in
  { num = num / g; den = den / g }
```

`make` is the only way to build a rational, and it normalizes on the way in: it moves the sign to the numerator and divides both parts by their greatest common divisor. Because every rational is born normalized, equality is just field equality, and the arithmetic stays simple:

```ocaml
let add a b = make ((a.num * b.den) + (b.num * a.den)) (a.den * b.den)
let sub a b = make ((a.num * b.den) - (b.num * a.den)) (a.den * b.den)
let mul a b = make (a.num * b.num) (a.den * b.den)
let div a b = make (a.num * b.den) (a.den * b.num)
```

Each operation runs the school-book formula and lets `make` reduce the answer. There is also `to_float` for when you need a number, and `to_string`, which hides the denominator when it is 1 so a whole number prints as `5`, not `5/1`.

## Modeling the Math

The file `src/types.ml` defines the objects the library works with. It starts with the small pieces. A *domain* says what kind of number a value ranges over, a *variable* pairs a name with a domain, and a *constant* is a named value that can be exact or one of the symbols pi and e:

```ocaml
type domain = Real | Complex | Integer_

type variable = { var_name : string; var_domain : domain }

type constant_value = ExactValue of Rational.t | SymbolicPi | SymbolicE
type constant = { const_name : string; const_value : constant_value }
```

The `constant_value` variant is the OCaml way to say "one of these shapes." A constant holds an exact rational, or the symbol pi, or the symbol e. When you need a number, one function maps each case to a float:

```ocaml
let constant_numeric_value c =
  match c.const_value with
  | SymbolicPi -> Float.pi
  | SymbolicE -> exp 1.0
  | ExactValue r -> Rational.to_float r
```

The building block of a polynomial is a *term*: one coefficient times a variable raised to a whole-number power, like `3x^2`:

```ocaml
type term = {
  term_coefficient : Rational.t;
  term_variable : variable;
  term_exponent : int;
}
```

Helpers negate a term and scale it, both with functional record update. `term_scale` multiplies just the coefficient and copies the rest:

```ocaml
let term_scale s t =
  { t with term_coefficient = Rational.mul s t.term_coefficient }
```

## Polynomials and Normalization

A polynomial is a variable, a list of terms, and a domain. The terms are kept in one canonical form: like powers combined, zero coefficients dropped, and the list sorted by descending exponent. The function `make_polynomial` enforces that form, so no other code has to worry about it:

```ocaml
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
  ...
```

It walks the terms and sums coefficients into a hash table keyed by exponent, so two `x^2` terms merge into one. Then it folds the table into a list, skipping any zero coefficient, and sorts by exponent from high to low. Because every polynomial passes through `make_polynomial`, addition can be careless: it just concatenates the two term lists and lets the constructor tidy up.

```ocaml
let polynomial_add p q =
  if not (variable_eq p.poly_variable q.poly_variable) then
    failwith (...)
  else
    make_polynomial p.poly_variable (p.poly_terms @ q.poly_terms) p.poly_domain
```

Adding polynomials in different variables is an error, so the function checks first and fails with a clear message. Subtraction negates the second polynomial and adds, and scaling maps `term_scale` over the terms.

## Evaluating a Polynomial

You can evaluate a polynomial two ways. The exact version keeps the answer as a rational; the float version is for gradients and definite integrals. Both fold over the terms, adding each term's contribution:

```ocaml
let polynomial_evaluate_q p x =
  List.fold_left
    (fun acc t ->
      Rational.add acc (Rational.mul t.term_coefficient (rat_pow x t.term_exponent)))
    Rational.zero p.poly_terms
```

`List.fold_left` runs an accumulator across the list. Here it starts at zero and adds `coefficient * x^exponent` for each term. Splitting into an exact and a float version is an OCaml habit: one function per numeric type, rather than one overloaded function, because the types are different.

## Differentiation

The file `src/differentiation.ml` applies the power rule. On one term, `d/dx (c * x^n)` is `n*c * x^(n-1)`, and a constant term (exponent 0) differentiates to nothing:

```ocaml
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
```

Returning an `option` is the key move. A constant term gives `None`, every other term gives `Some new_term`. To differentiate the whole polynomial, map this over the terms and drop the `None`s in one step with `List.filter_map`:

```ocaml
let differentiate p =
  let diff_terms = List.filter_map differentiate_term p.poly_terms in
  if diff_terms = [] then zero_polynomial p.poly_variable
  else make_polynomial p.poly_variable diff_terms p.poly_domain
```

`List.filter_map` applies a function that returns an `option` and keeps only the `Some` results, so it filters and maps at once. Higher derivatives come from applying `differentiate` `n` times, and `gradient_at` evaluates the derivative at a point:

```ocaml
let gradient_at p x = polynomial_evaluate (differentiate p) x
```

For `p = 3x^2 - x + 5`, the library gives `p' = 6x - 1`, `p'' = 6`, and `p''' = 0`. Evaluating `p'` at 0 gives -1, and at 1 gives 5, which the smoke test checks.

## Integration and Definite Integrals

The file `src/integration.ml` runs the power rule in reverse. The integral of `c * x^n` is `(c/(n+1)) * x^(n+1)`:

```ocaml
let integrate_term t =
  let new_exp = t.term_exponent + 1 in
  let new_coef = Rational.div t.term_coefficient (Rational.of_int new_exp) in
  {
    term_coefficient = new_coef;
    term_variable = t.term_variable;
    term_exponent = new_exp;
  }
```

Every term integrates (there is no exponent that fails), so `integrate` maps `integrate_term` over the terms without needing to drop anything. A definite integral uses the Fundamental Theorem of Calculus: integrate to get `F`, then compute `F(b) - F(a)`:

```ocaml
let evaluate_definite p lower upper =
  let f = integrate p in
  let a = resolve_bound_to_float lower in
  let b = resolve_bound_to_float upper in
  polynomial_evaluate f b -. polynomial_evaluate f a
```

A bound can be an exact number or a named constant, modeled by a small variant:

```ocaml
type bound = BNum of Rational.t | BConst of constant
```

So you can integrate from 0 to 1, or from 0 to pi, and `resolve_bound_to_float` turns either kind of bound into a number. For `p = 3x^2 - x + 5`, the integral is `x^3 - (1/2)x^2 + 5x`, and the definite integral from 0 to 1 is 5.5.

## Running It

Each module has a smoke test that prints its results, and `bin/main.ml` runs all three:

```ocaml
let () =
  Symbolic_math.Types.run_smoke_test ();
  Symbolic_math.Differentiation.run_smoke_test ();
  Symbolic_math.Integration.run_smoke_test ()
```

Build and run it, then run the Alcotest suite that checks the same cases:

```bash
cd source-code/symbolic_math
dune build
dune exec ./bin/main.exe
dune runtest
```

The output shows each polynomial in algebraic form, its derivatives, its integrals, and the definite integrals as exact numbers. Because the coefficients are exact rationals, `def [0,1] p dx` prints `5.5` with no rounding error. The whole library is a few hundred lines, and it shows how variant types, records, and pattern matching turn a math problem into clear OCaml.
