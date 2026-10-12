type t = Orange | Red | Blue | Green | Silver

val show : t -> string

(* Alphabetical by constructor name, like the Haskell custom Ord instance. *)
val compare : t -> t -> int
val equal : t -> t -> bool
val ( < ) : t -> t -> bool
val ( > ) : t -> t -> bool
