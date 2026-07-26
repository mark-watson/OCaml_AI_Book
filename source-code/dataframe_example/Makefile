.PHONY: clean check test

clean:
	dune clean
	rm -f data/housing_enriched.csv

check:
	dune build

test: check
	dune runtest
