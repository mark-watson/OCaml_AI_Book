let sample =
  {|{"query":{"original":"cats"},
     "web":{"results":[
       {"type":"search_result","title":"Cats","url":"https://example.com/cats",
        "description":"All about cats."},
       {"type":"search_result","url":"https://example.com/more"}
     ]}}|}

let test_suggestions () =
  let lines = Brave.suggestions_of_json (Yojson.Safe.from_string sample) in
  Alcotest.(check int) "query line + two results" 3 (List.length lines);
  Alcotest.(check string) "query line" "Original Query: cats" (List.hd lines)

let test_format_missing () =
  let r = Brave.web_result_of_json (Yojson.Safe.from_string {|{"type":"x"}|}) in
  Alcotest.(check string) "all N/A" "N/A | N/A | N/A" (Brave.format_result r)

let () =
  Alcotest.run "BraveSearch"
    [ ( "decode",
        [ Alcotest.test_case "suggestions" `Quick test_suggestions;
          Alcotest.test_case "missing fields" `Quick test_format_missing ] ) ]
