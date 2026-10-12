.PHONY: clean check test

clean:
	dune clean
	rm -f test.db

check:
	dune build

test: check
	dune runtest
