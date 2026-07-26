(* Build RDF (N3) triples from a text file and its .meta file. Ported from the
   Haskell GenTriples module. *)

let generate_triple s p o = s ^ "  " ^ p ^ "  " ^ o ^ " .\n"
let make_literal s = "\"" ^ s ^ "\""

let category_to_uri_map =
  [ ("news_weather", "<http://knowledgebooks.com/schema/topic/weather>");
    ("news_war", "<http://knowledgebooks.com/schema/topic/war>");
    ("economics", "<http://knowledgebooks.com/schema/topic/economics>");
    ("news_economy", "<http://knowledgebooks.com/schema/topic/economics>");
    ("news_politics", "<http://knowledgebooks.com/schema/topic/politics>");
    ("religion", "<http://knowledgebooks.com/schema/topic/religion>");
    ("religion_buddhism", "<http://knowledgebooks.com/schema/topic/religion/buddhism>");
    ("religion_islam", "<http://knowledgebooks.com/schema/topic/religion/islam>");
    ("religion_christianity", "<http://knowledgebooks.com/schema/topic/religion/christianity>");
    ("religion_hinduism", "<http://knowledgebooks.com/schema/topic/religion/hinduism>");
    ("religion_judaism", "<http://knowledgebooks.com/schema/topic/religion/judaism>");
    ("chemistry", "<http://knowledgebooks.com/schema/topic/chemistry>");
    ("computers", "<http://knowledgebooks.com/schema/topic/computers>");
    ("computers_ai", "<http://knowledgebooks.com/schema/topic/computers/ai>");
    ("computers_ai_datamining", "<http://knowledgebooks.com/schema/topic/computers/ai/datamining>");
    ("computers_ai_learning", "<http://knowledgebooks.com/schema/topic/computers/ai/learning>");
    ("computers_ai_nlp", "<http://knowledgebooks.com/schema/topic/computers/ai/nlp>");
    ("computers_ai_search", "<http://knowledgebooks.com/schema/topic/computers/ai/search>");
    ("computers_ai_textmining", "<http://knowledgebooks.com/schema/topic/computers/ai/textmining>");
    ("computers_programming", "<http://knowledgebooks.com/schema/topic/computers/programming>");
    ("computers_microsoft", "<http://knowledgebooks.com/schema/topic/computers/microsoft>");
    ("computers_programming_ruby", "<http://knowledgebooks.com/schema/topic/computers/programming/ruby>");
    ("computers_programming_lisp", "<http://knowledgebooks.com/schema/topic/computers/programming/lisp>");
    ("health", "<http://knowledgebooks.com/schema/topic/health>");
    ("health_exercise", "<http://knowledgebooks.com/schema/topic/health/exercise>");
    ("health_nutrition", "<http://knowledgebooks.com/schema/topic/health/nutrition>");
    ("mathematics", "<http://knowledgebooks.com/schema/topic/mathematics>");
    ("music", "<http://knowledgebooks.com/schema/topic/music>");
    ("physics", "<http://knowledgebooks.com/schema/topic/physics>");
    ("sports", "<http://knowledgebooks.com/schema/topic/sports>") ]

let uri_from_category key =
  match List.assoc_opt key category_to_uri_map with
  | Some u -> u
  | None -> "\"" ^ key ^ "\""

let schema s = "<http://knowledgebooks.com/schema/" ^ s ^ ">"

let text_to_triples ~onegrams ~twograms ~(emaps : File_utils.entity_maps)
    file_path meta_file_path =
  let word_tokens = File_utils.file_to_word_tokens file_path in
  let contents = File_utils.file_to_string file_path in
  let meta = File_utils.read_meta_file meta_file_path in
  let subj = meta.File_utils.uri in
  let names m = Entities.entity_names m word_tokens in
  let contains predicate pairs =
    String.concat ""
      (List.map (fun (_n, u) -> generate_triple subj (schema predicate) u) pairs)
  in
  let about predicate pairs =
    String.concat ""
      (List.map
         (fun (n, u) -> generate_triple u (schema predicate) (make_literal n))
         pairs)
  in
  let entity_block contains_pred about_pred m =
    let pairs = names m in
    contains contains_pred pairs ^ about about_pred pairs
  in
  let cats = Categorize.best_categories ~onegrams ~twograms word_tokens in
  let category_triples =
    cats
    |> List.filter (fun (_n, v) -> v > 0.3)
    |> List.map (fun (n, _) ->
           generate_triple subj (schema "news/category/") (uri_from_category n))
    |> String.concat ""
  in
  let summary = Summarize.summarize_s ~onegrams ~twograms contents in
  let summary_triple = generate_triple subj (schema "summaryOf") (make_literal summary) in
  String.concat ""
    [ entity_block "containsPersonDbPediaLink" "aboutPersonName" emaps.people;
      entity_block "containsCompanyDbPediaLink" "aboutCompanyName" emaps.companies;
      entity_block "containsCountryDbPediaLink" "aboutCountryName" emaps.countries;
      entity_block "containsCityDbPediaLink" "aboutCityName" emaps.cities;
      entity_block "containsBroadCastDbPediaLink" "aboutBroadCastName" emaps.broadcast_networks;
      entity_block "containsPoliticalPartyDbPediaLink" "aboutPoliticalPartyName" emaps.political_parties;
      entity_block "containsTradeUnionDbPediaLink" "aboutTradeUnionName" emaps.trade_unions;
      entity_block "containsUniversityDbPediaLink" "aboutUniversityName" emaps.universities;
      category_triples;
      summary_triple ]
