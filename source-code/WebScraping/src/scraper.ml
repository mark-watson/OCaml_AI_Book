(* HTML scraping with lambdasoup. Haskell used TagSoup; lambdasoup gives us CSS
   selectors, so link extraction is a one-line `select "a[href]"`. *)

let extract_texts html =
  Soup.parse html
  |> Soup.texts
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
  |> String.concat " "

let extract_links html =
  Soup.parse html
  |> Soup.select "a[href]"
  |> Soup.to_list
  |> List.filter_map (Soup.attribute "href")
