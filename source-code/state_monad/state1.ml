(* Haskell's State monad comes from the mtl library. OCaml has no such
   built-in, so we define a tiny State module. A stateful computation is a
   function from a starting state to a (result, new state) pair. *)

module State = struct
  type ('s, 'a) t = 's -> 'a * 's

  let return x s = (x, s)
  let bind m f s =
    let a, s' = m s in
    (f a) s'

  (* let* enables do-notation style sequencing *)
  let ( let* ) = bind
  let ( >>= ) = bind
  let ( >> ) m1 m2 = bind m1 (fun _ -> m2)

  let get s = (s, s)
  let put n _ = ((), n)

  let run_state (m : ('s, 'a) t) s = m s
  let eval_state (m : ('s, 'a) t) s = fst (m s)
  let exec_state (m : ('s, 'a) t) s = snd (m s)
  let map_state f (m : ('s, 'a) t) s = f (m s)
end

open State

(* Increment the state, returning the old value. do-notation style. *)
let increment_state =
  let* n = get in
  let* () = put (n + 1) in
  return n

(* The same computation written with the raw bind operators. *)
let increment_state2 = get >>= fun a -> put (a + 1) >> return a

(* Transform both the return value and the final state. *)
let bump_vals (a, b) = (a + 1, b + 2)

let () =
  let pr (a, b) = Printf.printf "(%d,%d)\n" a b in
  pr (run_state increment_state 1);
  pr (run_state increment_state2 1);
  pr (run_state (map_state bump_vals increment_state) 1);
  Printf.printf "%d\n" (eval_state increment_state 1);
  Printf.printf "%d\n" (exec_state increment_state 1)
