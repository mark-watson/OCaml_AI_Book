open Types

type rubber_state = {
  ns_below : int;
  ew_below : int;
  ns_above : int;
  ew_above : int;
  ns_games : int;
  ew_games : int;
  ns_vulnerable : bool;
  ew_vulnerable : bool;
  current_dealer : player;
  deals_played : int;
}

let new_rubber_state =
  {
    ns_below = 0; ew_below = 0; ns_above = 0; ew_above = 0; ns_games = 0;
    ew_games = 0; ns_vulnerable = false; ew_vulnerable = false;
    current_dealer = North; deals_played = 0;
  }

let trick_value strain doubled =
  let base =
    match strain with Suit_strain Clubs | Suit_strain Diamonds -> 20 | _ -> 30
  in
  let mult = match doubled with 1 -> 2 | 2 -> 4 | _ -> 1 in
  base * mult

let contract_trick_score level strain doubled =
  let base_per_trick = trick_value strain doubled in
  let extra =
    match (strain, doubled) with
    | No_trump, 0 -> 10 | No_trump, 1 -> 20 | No_trump, 2 -> 40 | _ -> 0
  in
  extra + (base_per_trick * level)

let score_rubber_deal level strain tricks_won declarer doubled rs =
  let tricks_needed = level + 6 in
  let overtricks = tricks_won - tricks_needed in
  let made = tricks_won >= tricks_needed in
  let ns_side = declarer = North || declarer = South in
  let vul = if ns_side then rs.ns_vulnerable else rs.ew_vulnerable in
  if made then begin
    let below_score = contract_trick_score level strain doubled in
    let overtrick_val =
      match doubled with
      | 0 -> trick_value strain 0
      | 1 -> if vul then 200 else 100
      | _ -> if vul then 400 else 200
    in
    let overtrick_bonus = if overtricks > 0 then overtricks * overtrick_val else 0 in
    let insult_bonus = match doubled with 1 -> 50 | 2 -> 100 | _ -> 0 in
    let slam_bonus =
      if level = 6 then if vul then 750 else 500
      else if level = 7 then if vul then 1500 else 1000
      else 0
    in
    let above_score = overtrick_bonus + insult_bonus + slam_bonus in
    let rs1, new_below =
      if ns_side then
        let nb = rs.ns_below + below_score in
        ({ rs with ns_below = nb; ns_above = rs.ns_above + above_score }, nb)
      else
        let nb = rs.ew_below + below_score in
        ({ rs with ew_below = nb; ew_above = rs.ew_above + above_score }, nb)
    in
    let rs2 =
      if new_below >= 100 then
        if ns_side then
          { rs1 with ns_games = rs1.ns_games + 1; ns_vulnerable = true;
                     ns_below = 0; ew_below = 0 }
        else
          { rs1 with ew_games = rs1.ew_games + 1; ew_vulnerable = true;
                     ns_below = 0; ew_below = 0 }
      else rs1
    in
    (rs2, below_score)
  end
  else begin
    let down = abs overtricks in
    let doubled_penalty () =
      if vul then 200 + ((down - 1) * 300)
      else
        match down with
        | 1 -> 100 | 2 -> 300 | 3 -> 500 | _ -> 500 + ((down - 3) * 300)
    in
    let penalty =
      match doubled with
      | 0 -> down * if vul then 100 else 50
      | 1 -> doubled_penalty ()
      | _ -> 2 * doubled_penalty ()
    in
    let rs1 =
      if ns_side then { rs with ew_above = rs.ew_above + penalty }
      else { rs with ns_above = rs.ns_above + penalty }
    in
    (rs1, -penalty)
  end

let rubber_complete rs = rs.ns_games >= 2 || rs.ew_games >= 2

let rubber_bonus rs =
  if rs.ns_games >= 2 then ((if rs.ew_games = 0 then 700 else 500), Some "N-S")
  else if rs.ew_games >= 2 then ((if rs.ns_games = 0 then 700 else 500), Some "E-W")
  else (0, None)

let rubber_total_scores rs =
  let bonus, winner = rubber_bonus rs in
  let ns_total = rs.ns_above + if winner = Some "N-S" then bonus else 0 in
  let ew_total = rs.ew_above + if winner = Some "E-W" then bonus else 0 in
  (ns_total, ew_total)
