(* Fetch a page, then print its response headers, visible text, and links. *)

open Lwt.Syntax

let fetch url =
  let* resp, body = Cohttp_lwt_unix.Client.get (Uri.of_string url) in
  let* body_str = Cohttp_lwt.Body.to_string body in
  Lwt.return (Cohttp.Response.headers resp, body_str)

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
