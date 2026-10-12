# Web Scraping - OCaml

OCaml port of the Haskell TagSoup example. It fetches a page over HTTPS and
prints the response headers, the visible text, and every link.

## Project layout

```
web_scraping/
├── src/scraper.ml  <- extract_texts and extract_links (lambdasoup)
├── bin/main.ml     <- fetch a URL and print the results
└── test/           <- Alcotest over a local HTML fixture
```

## Build and run

```bash
dune build
dune exec ./bin/main.exe
dune runtest
```

## Notes on the Haskell to OCaml port

- Haskell TagSoup becomes `lambdasoup`. Because lambdasoup supports CSS
  selectors, `extractLinks` becomes `Soup.select "a[href]"` plus
  `Soup.attribute "href"`.
- `httpLBS` becomes `Cohttp_lwt_unix.Client.get`; the HTTPS backend is `tls-lwt`.
- The Haskell integration test scraped `example.com` live. The OCaml test parses
  a local fixture of the same shape so it runs offline.

## License

Apache 2.0 - Copyright 2016-2026 Mark Watson. All rights reserved.
