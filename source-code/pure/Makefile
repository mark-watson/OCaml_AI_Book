EXES = simple conditionals if_then_else guards cases let_and_where \
       chained_calls map_examples my_colors

.PHONY: clean check test

clean:
	dune clean

check:
	dune build

test: check
	@set -e; for exe in $(EXES); do echo "--- $$exe ---"; dune exec ./$$exe.exe; done
