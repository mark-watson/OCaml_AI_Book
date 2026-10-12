# Conclusions

Thank you, dear reader, for spending time with this book. We covered a lot of ground: the OCaml language itself, functional patterns like a hand-built `State` module, the same state with OCaml 5 effect handlers, and lazy sequences, symbolic math, text processing and natural language, databases, RDF and SPARQL, web scraping, network and web programming with Lwt and Dream, clients for large language models and search, a knowledge graph builder, three games with AI players and parallel playouts on OCaml 5 domains, and a neural network trained from scratch.

Two themes run through the whole book. The first is that OCaml's type system is a help, not a chore. When the compiler accepts a program that takes a request type and returns a response type, most of the small mistakes are already gone. The second is that you can build a lot from a small, sharp standard library plus a handful of well-chosen packages: Yojson for JSON, Cohttp and Lwt for HTTP, Dream for the web, Caqti for SQL, and Alcotest for tests.

The examples are mine, written for my own projects and my own enjoyment, and I hope they save you time on yours. Take any file as a starting point, change it, and make it your own.

If you find a bug or want to add an example, please open a pull request on the [GitHub repository](https://github.com/mark-watson/OCaml_AI_Book). I read every one.

Happy hacking in OCaml.

Mark Watson
