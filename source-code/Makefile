# Recurses into each example project. One rule covers all three targets:
# $@ is whichever of clean/check/test was requested.
SUBDIRS = \
  pure state_monad symbolic_math text_processing fast_tag rdf_sparql \
  ollama_commandline debugging timers testing impure command_line_app \
  database_sqlite client_server web_scraping openai_api_client brave_search \
  gemini_commandline sparql_client webchat dataframe_example blackjack \
  nlp_tool knowledge_graph_creator bridge_game go_playing_program \
  webview bridge_webkit neural_network

.PHONY: clean check test

.DEFAULT_GOAL := check

clean check test:
	@for d in $(SUBDIRS); do \
	  echo "==> $$d: make $@"; \
	  $(MAKE) --no-print-directory -C $$d $@ || exit $$?; \
	done
