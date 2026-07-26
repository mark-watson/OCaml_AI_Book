#!/usr/bin/env python3
"""Convert the Haskell NlpTool data modules (Map.fromList literals) into TSV
files that the OCaml port loads at runtime. Run once from the NlpTool dir:

    python3 convert_data.py /path/to/haskell_book/source-code/NlpTool/src/nlp/data
"""
import os
import re
import sys

SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(OUT, exist_ok=True)

pair_str = re.compile(r'\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)')
pair_num = re.compile(r'\("((?:[^"\\]|\\.)*)",\s*(-?[0-9.]+)\)')

entity_files = {
    "BroadcastNetworkNamesDbPedia.hs": "broadcast_networks.tsv",
    "CityNamesDbpedia.hs": "cities.tsv",
    "CompanyNamesDbpedia.hs": "companies.tsv",
    "CountryNamesDbpedia.hs": "countries.tsv",
    "PeopleDbPedia.hs": "people.tsv",
    "PoliticalPartyNamesDbPedia.hs": "political_parties.tsv",
    "TradeUnionNamesDbPedia.hs": "trade_unions.tsv",
    "UniversityNamesDbPedia.hs": "universities.tsv",
}

for hs, tsv in entity_files.items():
    text = open(os.path.join(SRC, hs), encoding="utf-8").read()
    pairs = pair_str.findall(text)
    with open(os.path.join(OUT, tsv), "w", encoding="utf-8") as f:
        for name, uri in pairs:
            name = name.strip()
            if name:
                f.write(f"{name}\t{uri}\n")
    print(f"{tsv}: {len(pairs)} entries")

# Category ngrams: each "category = M.fromList [...]" line becomes rows of
# category<TAB>word<TAB>score. Skip the trailing onegrams/twograms index line.
ngram_files = {"Category1Gram.hs": "category_1gram.tsv",
               "Category2Gram.hs": "category_2gram.tsv"}
line_re = re.compile(r'^(\w+)\s*=\s*M\.fromList\s*\[(.*)\]\s*$')
for hs, tsv in ngram_files.items():
    rows = 0
    with open(os.path.join(OUT, tsv), "w", encoding="utf-8") as out:
        for line in open(os.path.join(SRC, hs), encoding="utf-8"):
            m = line_re.match(line.strip())
            if not m:
                continue
            category = m.group(1)
            if category in ("onegrams", "twograms"):
                continue
            for word, score in pair_num.findall(m.group(2)):
                out.write(f"{category}\t{word}\t{score}\n")
                rows += 1
    print(f"{tsv}: {rows} rows")
