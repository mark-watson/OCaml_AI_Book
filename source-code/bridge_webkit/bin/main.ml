(* Rubber bridge as a Dream web app: the browser page (app/index.html) drives an
   AI opponent through the bridge engine. The Haskell version was a native
   WebKit window; here the same JS bridge (window.webkit_haskell.invoke) POSTs to
   /bridge/<command>. The human plays South. *)

open Bwk
open Bwk.Types
open Bwk.Engine
open Lwt.Syntax

type active = {
  gs : game_state;
  rs : Scoring.rubber_state;
  seed : int;
  last_trick : Yojson.Safe.t;
}

let rec run_ai_bidding gs =
  if gs.phase <> Bidding then gs
  else
    match current_actor gs with
    | Some South -> gs
    | Some actor ->
      run_ai_bidding
        (apply_bid
           (Bidding.ai_select_bid (PMap.find actor gs.hands) gs.bid_history actor gs.dealer)
           gs)
    | None -> gs

let play_card_and_step card actor state =
  let gs = state.gs in
  let current_trick' = (actor, card) :: gs.current_trick in
  let completed =
    if List.length current_trick' = 4 then
      `List (List.rev_map (fun (p, c) -> Payload.played_card p c) current_trick')
    else `List []
  in
  let gs' = apply_card_play card gs in
  let state' =
    if gs'.phase = Scoring then (
      let contract = match gs'.contract with Some c -> c | None -> Suit_bid (1, No_trump) in
      let level, strain = match contract with Suit_bid (l, s) -> (l, s) | _ -> (1, No_trump) in
      let declarer = match gs'.declarer with Some d -> d | None -> South in
      let tricks_won = if side declarer = 0 then gs'.tricks_ns else gs'.tricks_ew in
      let rs', _ = Scoring.score_rubber_deal level strain tricks_won declarer gs'.doubled state.rs in
      let rs'' =
        { rs' with Scoring.deals_played = rs'.Scoring.deals_played + 1;
                   current_dealer = next_player rs'.Scoring.current_dealer }
      in
      { state with gs = gs'; rs = rs'' })
    else { state with gs = gs' }
  in
  { state' with last_trick = completed }

let next_deal state =
  let rs = state.rs in
  let vul =
    match (rs.Scoring.ns_vulnerable, rs.Scoring.ew_vulnerable) with
    | true, true -> Both | true, false -> Ns_only | false, true -> Ew_only
    | false, false -> Vul_none
  in
  let gs = run_ai_bidding (new_game rs.Scoring.current_dealer vul South state.seed) in
  { gs; rs; seed = Random.int 1_000_000_000; last_trick = `List [] }

let make_initial seed =
  {
    gs = run_ai_bidding (new_game North Vul_none South seed);
    rs = Scoring.new_rubber_state;
    seed = Random.int 1_000_000_000;
    last_trick = `List [];
  }

let state = ref (make_initial 42)

let get_string p key =
  match p with
  | `Assoc kv -> (
    match List.assoc_opt key kv with Some (`String s) -> s | _ -> "")
  | _ -> ""

let payload_of () =
  Payload.make_payload !state.gs !state.rs (!state.rs.Scoring.deals_played + 1)
    !state.last_trick

let handle cmd payload =
  match cmd with
  | "get-state" -> payload_of ()
  | "reset-game" ->
    state := { (make_initial !state.seed) with rs = Scoring.new_rubber_state };
    payload_of ()
  | "next-deal" ->
    state := next_deal !state;
    payload_of ()
  | "bid" -> (
    let bid_str = get_string payload "bid" in
    match Parsing.parse_bid_input bid_str with
    | None -> `Assoc [ ("error", `String ("Failed to parse bid: " ^ bid_str)) ]
    | Some bid ->
      let gs = !state.gs in
      let current_highest = Bidding.last_suit_bid gs.bid_history in
      let is_legal =
        match (bid, current_highest) with
        | Suit_bid _, Some ch -> Bidding.bid_higher_than bid ch
        | _ -> true
      in
      if not is_legal then
        `Assoc [ ("error", `String ("Bid " ^ bid_str ^ " is not legal.")) ]
      else begin
        let gs' = run_ai_bidding (apply_bid bid gs) in
        state :=
          (if gs'.phase = Done then next_deal !state
           else { !state with gs = gs'; last_trick = `List [] });
        payload_of ()
      end)
  | "play-card" -> (
    let card_str = get_string payload "card" in
    let gs = !state.gs in
    match current_actor gs with
    | Some act -> (
      let lead_suit =
        match Payload.last_of gs.current_trick with
        | Some (_, c) -> Some (card_suit c)
        | None -> None
      in
      let legal = Play.legal_plays (PMap.find act gs.hands) lead_suit in
      match List.find_opt (fun c -> show_card c = card_str) legal with
      | Some card ->
        state := play_card_and_step card act !state;
        payload_of ()
      | None -> `Assoc [ ("error", `String ("Card " ^ card_str ^ " is not a legal play.")) ])
    | None -> `Assoc [ ("error", `String "No active player found.") ])
  | "ai-play-single" -> (
    let gs = !state.gs in
    match current_actor gs with
    | Some actor ->
      let is_human = actor = South in
      let is_dummy = Some actor = gs.dummy in
      let declarer_side = Option.map side gs.declarer in
      let human_plays_this = is_human || (is_dummy && declarer_side = Some 0) in
      if human_plays_this then
        `Assoc [ ("error", `String "It is human's turn to play, not AI.") ]
      else begin
        let card =
          Play.ai_select_card (PMap.find actor gs.hands)
            (List.rev_map snd gs.current_trick)
            gs.trick_lead gs.trump_suit actor
            (Option.value ~default:South gs.declarer)
        in
        state := play_card_and_step card actor !state;
        payload_of ()
      end
    | None -> `Assoc [ ("error", `String "No active player found.") ])
  | other -> `Assoc [ ("error", `String ("Unknown command: " ^ other)) ]

let bridge_js =
  {js|<script>window.webkit_haskell = { invoke: async function (c, p) {
    const r = await fetch('/bridge/' + c, { method: 'POST',
      headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(p || {}) });
    return await r.json(); } };</script>|js}

let read_file path =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic)
    (fun () -> really_input_string ic (in_channel_length ic))

let find_sub sub s =
  let ls = String.length s and lsub = String.length sub in
  let rec go i =
    if i + lsub > ls then None
    else if String.sub s i lsub = sub then Some i
    else go (i + 1)
  in
  go 0

(* Insert the JS bridge shim right before </head> (else at the top). *)
let inject_bridge html =
  match find_sub "</head>" html with
  | Some i -> String.sub html 0 i ^ bridge_js ^ String.sub html i (String.length html - i)
  | None -> bridge_js ^ html

let () =
  Random.self_init ();
  state := make_initial (Random.int 1_000_000_000);
  let html = inject_bridge (read_file "app/index.html") in
  print_endline "Rubber bridge on http://127.0.0.1:8080/";
  Dream.run ~interface:"127.0.0.1" ~port:8080
  @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/" (fun _ -> Dream.html html);
         Dream.post "/bridge/:command" (fun req ->
             let command = Dream.param req "command" in
             let* body = Dream.body req in
             let payload = try Yojson.Safe.from_string body with _ -> `Null in
             Dream.json (Yojson.Safe.to_string (handle command payload)))
       ]
