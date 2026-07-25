EXES = state1

.PHONY: clean check test

clean:
	dune clean

check:
	dune build

test: check
	@set -e; for exe in $(EXES); do echo "--- $$exe ---"; dune exec ./$$exe.exe; done
