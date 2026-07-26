module D = Dataframe

let df () =
  D.make
    ~columns:[ "city"; "rooms"; "households" ]
    ~rows:
      [ [ "A"; "100"; "10" ];
        [ "A"; "200"; "20" ];
        [ "B"; "90"; "30" ] ]

let cell t r c = t.D.rows.(r).(D.index t c)

let test_derive () =
  let t = D.derive (df ()) "rooms_per_hh" (fun g -> g "rooms" /. g "households") in
  Alcotest.(check string) "row 0" "10" (cell t 0 "rooms_per_hh")

let test_filter () =
  let t = D.filter_string (df ()) "city" (fun c -> c = "A") in
  Alcotest.(check int) "two A rows" 2 (D.n_rows t)

let test_group () =
  let t =
    D.group_by (df ()) ~key:"city"
      ~aggs:[ ("n", D.Count); ("avg_rooms", D.Mean "rooms") ]
  in
  Alcotest.(check int) "two groups" 2 (D.n_rows t);
  Alcotest.(check string) "A avg rooms" "150" (cell t 0 "avg_rooms")

let test_sort () =
  let t = D.sort_by_float ~desc:true (df ()) "rooms" in
  Alcotest.(check string) "max first" "200" (cell t 0 "rooms")

let () =
  Alcotest.run "dataframe"
    [ ( "ops",
        [ Alcotest.test_case "derive" `Quick test_derive;
          Alcotest.test_case "filter" `Quick test_filter;
          Alcotest.test_case "group" `Quick test_group;
          Alcotest.test_case "sort" `Quick test_sort ] ) ]
