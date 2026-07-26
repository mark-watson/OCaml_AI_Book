(* The Haskell test fetched example.com live. To keep the suite offline and
   deterministic we parse the same shape of page from a local fixture. *)

let sample =
  "<html><head><title>t</title></head><body>\
   <h1>Example Domain</h1>\
   <p>This domain is for use in illustrative examples.</p>\
   <a href=\"https://www.iana.org/domains/example\">More information...</a>\
   </body></html>"

let contains ~needle s =
  let nl = String.length needle and sl = String.length s in
  let rec go i = i + nl <= sl && (String.sub s i nl = needle || go (i + 1)) in
  nl = 0 || go 0

let test_texts () =
  let texts = Scraper.extract_texts sample in
  Alcotest.(check bool) "has heading" true (contains ~needle:"Example Domain" texts)

let test_links () =
  let links = Scraper.extract_links sample in
  Alcotest.(check bool) "non-empty" true (links <> []);
  Alcotest.(check bool) "has iana link" true
    (List.exists (contains ~needle:"iana.org") links)

let () =
  Alcotest.run "WebScraping"
    [ ( "extract",
        [ Alcotest.test_case "text" `Quick test_texts;
          Alcotest.test_case "links" `Quick test_links ] ) ]
