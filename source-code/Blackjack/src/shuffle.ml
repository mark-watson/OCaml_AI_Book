(* Fisher-Yates shuffle, the OCaml stand-in for the Haskell RandomizedList
   module. Seed the generator once (Random.self_init) in the program. *)

let shuffle lst =
  let a = Array.of_list lst in
  for i = Array.length a - 1 downto 1 do
    let j = Random.int (i + 1) in
    let tmp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- tmp
  done;
  Array.to_list a
