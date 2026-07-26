(* Alcotest suite, mirroring the Haskell HSpec `Spec.hs`.

   The Haskell original left one assertion deliberately wrong to show what a
   failure looks like. Here every case passes so `make test` stays green across
   the whole book; the README explains where the intentional failure was. *)

let test_head () =
  Alcotest.(check int) "first Int" 1 (List.hd [ 1; 2; 3; 4 ]);
  Alcotest.(check string) "first string" "the" (List.hd [ "the"; "dog"; "ran" ])

let test_head_empty () =
  Alcotest.check_raises "empty list raises"
    (Failure "hd") (fun () -> ignore (List.hd ([] : int list)))

let test_descending () =
  Alcotest.(check bool) "Green < Red" true My_colors.(Green < Red)

let test_ascending () =
  Alcotest.(check bool) "Red > Silver is false" false My_colors.(Red > Silver)

let () =
  Alcotest.run "MyColors"
    [ ( "head",
        [ Alcotest.test_case "returns the first element" `Quick test_head;
          Alcotest.test_case "throws on empty list" `Quick test_head_empty ] );
      ( "MyColors",
        [ Alcotest.test_case "custom compare descending" `Quick test_descending;
          Alcotest.test_case "custom compare ascending" `Quick test_ascending ] );
    ]
