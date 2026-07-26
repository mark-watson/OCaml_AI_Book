# Web Scraping

Web scraping is two jobs: fetch a page over HTTP, then pull the parts you want out of its HTML. The example in `source-code/WebScraping/` does both. It uses [Cohttp](https://github.com/mirage/ocaml-cohttp) with a TLS backend to fetch a page over HTTPS, and [lambdasoup](https://github.com/aantron/lambdasoup) to parse the HTML and select elements with CSS selectors.

## Parsing HTML

The file `src/scraper.ml` holds the two extractors, and they are short because lambdasoup does the heavy lifting. The first collects all the visible text on the page:

```ocaml
let extract_texts html =
  Soup.parse html
  |> Soup.texts
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
  |> String.concat " "
```

`Soup.parse` turns an HTML string into a document. `Soup.texts` returns every text node. The rest of the pipeline trims each piece, drops the blank ones, and joins the rest with single spaces, so you get the page's readable text as one clean string.

The second extractor collects every link. Because lambdasoup supports CSS selectors, this is nearly a one-liner:

```ocaml
let extract_links html =
  Soup.parse html
  |> Soup.select "a[href]"
  |> Soup.to_list
  |> List.filter_map (Soup.attribute "href")
```

`Soup.select "a[href]"` finds every `<a>` tag that has an `href` attribute, the same selector you would use in CSS or the browser console. `Soup.to_list` turns the selection into a list, and `List.filter_map (Soup.attribute "href")` reads each tag's `href`, dropping any that lack one. The CSS selector replaces the manual tag-walking a lower-level HTML parser would need.

The interface file `src/scraper.mli` keeps the module's surface to just these two functions:

```ocaml
val extract_texts : string -> string
val extract_links : string -> string list
```

Both take an HTML string, so they are pure and easy to test against a fixture with no network.

## Fetching a Page

The program in `bin/main.ml` fetches a URL and prints its headers, text, and links. Fetching is a short Lwt function:

```ocaml
open Lwt.Syntax

let fetch url =
  let* resp, body = Cohttp_lwt_unix.Client.get (Uri.of_string url) in
  let* body_str = Cohttp_lwt.Body.to_string body in
  Lwt.return (Cohttp.Response.headers resp, body_str)
```

`Cohttp_lwt_unix.Client.get` sends the request and returns a response and a streaming body. The `let*` from `Lwt.Syntax` waits for each promise, the same syntax the SPARQL client used. `Cohttp_lwt.Body.to_string` reads the whole body into a string, and the function returns the response headers alongside it.

One dependency makes the HTTPS work. The `bin/dune` file lists `tls-lwt`:

```
(executable
 (name main)
 (libraries scraper cohttp-lwt-unix lwt.unix uri tls-lwt))
```

`tls-lwt` is the TLS backend that Cohttp uses for `https://` URLs. Without it, Cohttp can speak plain HTTP but not HTTPS. You do not call it directly; linking it in is enough.

## Putting It Together

The main function fetches the page, prints the three sections, and wraps the whole thing in `Lwt.catch` so a network failure prints a message instead of crashing:

```ocaml
let () =
  let url = "https://markwatson.com/" in
  Lwt_main.run
    (Lwt.catch
       (fun () ->
         let* headers, body = fetch url in
         print_endline "Headers:";
         print_string (Cohttp.Header.to_string headers);
         print_endline "\nText Content:";
         print_endline (Scraper.extract_texts body);
         print_endline "\nLinks:";
         List.iter print_endline (Scraper.extract_links body);
         Lwt.return_unit)
       (fun exn ->
         Printf.printf "Network error: %s\n" (Printexc.to_string exn);
         Lwt.return_unit))
```

`Lwt_main.run` starts the event loop and runs the whole action. The body fetches the page and prints its headers, its visible text, and every link. The handler turns any exception, a DNS failure or a dropped connection, into a printed line.

## Running It

```bash
cd source-code/WebScraping
dune build
dune exec ./bin/main.exe
dune runtest
```

The program prints the response headers, the page text as one string, and one link per line. The test runs offline: it parses a local HTML fixture of the same shape and checks that `extract_texts` and `extract_links` return the expected values, so `dune runtest` needs no network. Splitting the pure extractors from the network fetch is what makes that offline test possible, and it is a pattern worth copying: keep parsing separate from I/O, and you can test the hard part without a server.
