(* Pattern matching and simple recursion over lists *)

let show_int_list xs =
  "[" ^ String.concat "," (List.map string_of_int xs) ^ "]"

let show_float_list xs =
  "[" ^ String.concat "," (List.map (Printf.sprintf "%g") xs) ^ "]"

let head' = function
  | x :: _ -> x
  | [] -> failwith "head': empty list"

let tail' = function
  | _ :: xs -> xs
  | [] -> failwith "tail': empty list"

let rec double_list = function
  | [] -> []
  | x :: xs -> (2 * x) :: double_list xs

let rec bump_list n = function
  | [] -> []
  | x :: xs -> (n * x) :: bump_list n xs

let rec map' f = function
  | [] -> []
  | x :: xs -> f x :: map' f xs

let range a b = List.init (b - a + 1) (fun i -> a + i)

let () =
  print_endline (head' ["bird"; "dog"; "cat"]);
  print_endline (show_int_list (tail' [0; 1; 2; 3; 4; 5]));
  print_endline (show_int_list (double_list (range 0 5)));
  print_endline (show_int_list (bump_list 3 (range 0 5)));
  print_endline (show_int_list (map' (fun x -> x * 7) (range 0 5)));
  print_endline (show_float_list (map' (fun x -> x +. 1.1) [0.; 1.; 2.; 3.; 4.; 5.]));
  print_endline (show_int_list (map' (fun x -> (x + 1) * 2) (range 0 5)))
