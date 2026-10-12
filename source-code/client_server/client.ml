(* TCP client: connect, send "test123", print the reversed reply. *)

open Lwt.Syntax

let () =
  Lwt_main.run
    (Lwt.catch
       (fun () ->
         let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
         let addr = Unix.(ADDR_INET (inet_addr_loopback, 3000)) in
         let* () = Lwt_unix.connect sock addr in
         print_endline "Connection established to 127.0.0.1:3000";
         let msg = Bytes.of_string "test123" in
         let* _ = Lwt_unix.send sock msg 0 (Bytes.length msg) [] in
         let buf = Bytes.create 100 in
         let* n = Lwt_unix.recv sock buf 0 100 [] in
         if n = 0 then print_endline "No response from server"
         else Printf.printf "Response: %s\n" (Bytes.sub_string buf 0 n);
         Lwt_unix.close sock)
       (fun exn ->
         Printf.printf "Connection error: %s\n" (Printexc.to_string exn);
         Lwt.return_unit))
