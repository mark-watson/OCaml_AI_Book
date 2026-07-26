# Recurses into each example project. One rule covers all three targets:
# $@ is whichever of clean/check/test was requested.
SUBDIRS = \
  Pure StateMonad SymbolicMath TextProcessing FastTag rdf_sparql \
  ollama_commandline debugging Timers Testing ImPure CommandLineApp \
  Database-sqlite ClientServer WebScraping OpenAiApiClient BraveSearch \
  gemini_commandline SparqlClient webchat dataframe_example Blackjack \
  NlpTool knowledge_graph_creator Bridge_game Go_playing_program \
  webview Bridge_webkit

.PHONY: clean check test

.DEFAULT_GOAL := check

clean check test:
	@for d in $(SUBDIRS); do \
	  echo "==> $$d: make $@"; \
	  $(MAKE) --no-print-directory -C $$d $@ || exit $$?; \
	done
