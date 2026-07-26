(* TCP server: for each connection, reverse every chunk of bytes received and
   send it back, until the client disconnects. Haskell used network-simple; here
   we use Lwt's Unix sockets directly, which maps recv/send one to one. *)

open Lwt.Syntax

let reverse_bytes b n =
  let out = Bytes.create n in
  for i = 0 to n - 1 do
    Bytes.set out i (Bytes.get b (n - 1 - i))
  done;
  out

let string_of_addr = function
  | Unix.ADDR_INET (a, p) -> Printf.sprintf "%s:%d" (Unix.string_of_inet_addr a) p
  | Unix.ADDR_UNIX s -> s

let rec reverse_loop sock =
  let buf = Bytes.create 4096 in
  let* n = Lwt_unix.recv sock buf 0 4096 [] in
  if n = 0 then Lwt.return_unit
  else
    let* _ = Lwt_unix.send sock (reverse_bytes buf n) 0 n [] in
    reverse_loop sock

let () =
  Lwt_main.run
    (let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
     Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true;
     let addr = Unix.(ADDR_INET (inet_addr_loopback, 3000)) in
     let* () = Lwt_unix.bind sock addr in
     Lwt_unix.listen sock 10;
     Printf.printf "Listening at %s\n%!" (string_of_addr addr);
     let rec accept_loop () =
       let* client, caddr = Lwt_unix.accept sock in
       Printf.printf "Connection from %s\n%!" (string_of_addr caddr);
       (* One lightweight thread per client, like Haskell's acceptFork. *)
       Lwt.async (fun () ->
           Lwt.finalize
             (fun () -> reverse_loop client)
             (fun () -> Lwt_unix.close client));
       accept_loop ()
     in
     accept_loop ())
