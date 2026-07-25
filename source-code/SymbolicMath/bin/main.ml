(* Smoke test runner for the symbolic math library. *)

let () =
  Symbolic_math.Types.run_smoke_test ();
  Symbolic_math.Differentiation.run_smoke_test ();
  Symbolic_math.Integration.run_smoke_test ()
