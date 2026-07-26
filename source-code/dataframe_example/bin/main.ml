(* California housing analysis, mirroring the Haskell `dataframe` example. Run
   from the project root so ./data/housing.csv resolves. *)

module D = Dataframe

let separator () = print_endline (String.make 70 '-')

let () =
  let df =
    try D.read_csv "./data/housing.csv"
    with Sys_error err ->
      Printf.printf "ERROR: Could not load CSV file: %s\n" err;
      print_endline "Make sure you are running from the dataframe_example root.";
      exit 1
  in

  print_endline "\n=== California Housing Dataset ===";
  print_endline "First 5 rows:";
  D.print ~max_rows:5 df;
  separator ();

  print_endline "\n=== Summary Statistics ===";
  D.print (D.summarize df);
  separator ();

  (* Derived columns. *)
  let enriched =
    df
    |> fun d ->
    D.derive d "rooms_per_household" (fun g -> g "total_rooms" /. g "households")
    |> fun d ->
    D.derive d "population_per_household" (fun g ->
        g "population" /. g "households")
    |> fun d ->
    D.derive d "bedrooms_per_room" (fun g ->
        g "total_bedrooms" /. g "total_rooms")
  in
  print_endline "\n=== Derived Columns (first 5 rows) ===";
  D.print ~max_rows:5 enriched;
  separator ();

  (* Filter: high-value coastal properties. *)
  let coastal = [ "NEAR BAY"; "NEAR OCEAN"; "<1H OCEAN" ] in
  let expensive =
    enriched
    |> (fun d -> D.filter_float d "median_house_value" (fun v -> v > 400000.))
    |> fun d -> D.filter_string d "ocean_proximity" (fun p -> List.mem p coastal)
  in
  print_endline "\n=== Expensive Coastal Properties (value > $400k) ===";
  Printf.printf "Row count: %d\n" (D.n_rows expensive);
  D.print ~max_rows:5
    (D.select expensive
       [ "ocean_proximity"; "median_income"; "median_house_value";
         "rooms_per_household"; "population_per_household" ]);
  separator ();

  (* Sort by median house value, descending. *)
  print_endline "\n=== Top 5 Most Expensive Properties ===";
  D.print ~max_rows:5 (D.sort_by_float ~desc:true enriched "median_house_value");
  separator ();

  (* Group by ocean proximity, aggregate. *)
  let by_proximity =
    D.group_by enriched ~key:"ocean_proximity"
      ~aggs:
        [ ("num_districts", D.Count);
          ("avg_house_value", D.Mean "median_house_value");
          ("avg_income", D.Mean "median_income");
          ("avg_rooms_per_hh", D.Mean "rooms_per_household") ]
    |> fun d -> D.sort_by_float ~desc:true d "avg_house_value"
  in
  print_endline "\n=== Average House Value by Ocean Proximity ===";
  D.print by_proximity;
  separator ();

  (* Write the enriched dataset. *)
  D.write_csv "./data/housing_enriched.csv" enriched;
  print_endline "\nEnriched dataset written to ./data/housing_enriched.csv"
