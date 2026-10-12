(* The State example again, this time with OCaml 5 effect handlers instead of a
   monad. Stateful code is written in direct style: get () and put n are
   ordinary function calls that perform an effect, and run_state installs a
   handler that answers them. Needs OCaml 5.3 or later for the
   "effect" pattern syntax in match. *)

module State (S : sig type t end) = struct
  type _ Effect.t += Get : S.t Effect.t | Put : S.t -> unit Effect.t

  let get () = Effect.perform Get
  let put n = Effect.perform (Put n)

  (* The handler turns the computation into a function from a start state to
     (result, final state), the same shape as the monad's type. Each case
     returns such a function; continuing k resumes the computation, still under
     this handler, and passes the state to whatever it returns. *)
  let run_state (f : unit -> 'a) (init : S.t) : 'a * S.t =
    let step =
      match f () with
      | v -> fun s -> (v, s)
      | effect Get, k -> fun (s : S.t) -> Effect.Deep.continue k s s
      | effect (Put s'), k -> fun _ -> Effect.Deep.continue k () s'
    in
    step init

  let eval_state f s = fst (run_state f s)
  let exec_state f s = snd (run_state f s)
  let map_state g f s = g (run_state f s)
end

module IntState = State (struct type t = int end)
open IntState

(* Increment the state, returning the old value. Plain sequential code. *)
let increment_state () =
  let n = get () in
  put (n + 1);
  n

let bump_vals (a, b) = (a + 1, b + 2)

(* Direct style pays off with library code: List.iter knows nothing about
   state, yet the callback can read and update it. The monad version would need
   a monadic iter written for the purpose. *)
let count_long_words words =
  List.iter (fun w -> if String.length w > 3 then put (get () + 1)) words

let () =
  let pr (a, b) = Printf.printf "(%d,%d)\n" a b in
  pr (run_state increment_state 1);
  pr (map_state bump_vals increment_state 1);
  Printf.printf "%d\n" (eval_state increment_state 1);
  Printf.printf "%d\n" (exec_state increment_state 1);
  Printf.printf "long words: %d\n"
    (exec_state
       (fun () -> count_long_words [ "the"; "state"; "flows"; "through"; "it" ])
       0)
