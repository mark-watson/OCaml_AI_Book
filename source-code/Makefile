# Recurses into each example project. One rule covers all three targets:
# $@ is whichever of clean/check/test was requested.
SUBDIRS = FastTag ollama_commandline Pure rdf_sparql StateMonad SymbolicMath TextProcessing

.PHONY: clean check test

.DEFAULT_GOAL := check

clean check test:
	@for d in $(SUBDIRS); do \
	  echo "==> $$d: make $@"; \
	  $(MAKE) --no-print-directory -C $$d $@ || exit $$?; \
	done
