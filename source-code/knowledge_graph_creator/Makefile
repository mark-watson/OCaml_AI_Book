.PHONY: clean check test

clean:
	dune clean
	rm -f out.n3 out.cypher

check:
	dune build

test: check
	dune runtest
