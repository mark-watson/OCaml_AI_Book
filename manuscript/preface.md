# Preface

OCaml is a practical language in the ML family. It has a strong static type system that catches many errors before your code runs, type inference that keeps the code short, pattern matching that makes data easy to take apart, and a fast native compiler. You get the safety of a typed language and much of the ease of a scripting language at the same time.

Dear reader, I enjoy writing OCaml and I hope you will too. OCaml ships with a good package manager (opam) and a fast build tool (dune). Around that core sits a large set of open source libraries for JSON, HTTP, web servers, databases, and more. This book shows you how to put those pieces together to build practical Artificial Intelligence (AI) and data processing programs.

I have written commercial AI tools and applications since the 1980s. I usually work in Lisp languages and in the ML family of languages that OCaml belongs to. The code here is code that I wrote for my own use, and I wrap it in a book in the hope that it also helps you.

![Mark Watson](images/Mark.png)

I wrote this book for programmers who already know how to code and who want to learn practical AI and data techniques in OCaml. You do not need to be an OCaml expert. Chapter 1 is a short tutorial that covers the parts of the language the examples use. After that, the chapters follow the plan of a cook book: read them in any order and take what you need.

The examples in this book are OCaml ports of the code from my Haskell AI book. Each chapter explains the OCaml version on its own terms, so you do not need the Haskell book to follow along. Where the port made an interesting choice, I point it out.

You can find the code examples and the manuscript files for this book in this GitHub repository:

[https://github.com/mark-watson/OCaml_AI_Book](https://github.com/mark-watson/OCaml_AI_Book)

The latest edition is always available to buy at [https://leanpub.com/ocaml-ai](https://leanpub.com/ocaml-ai). You can also read it free online at [https://leanpub.com/ocaml-ai/read](https://leanpub.com/ocaml-ai/read). I offer the purchase option for readers who want to support my work.

This is a "live book": there will never be a second edition. As I add material and fix errors, I update the book, and both the free online copy and every eBook format for purchase get the update.

I welcome git pull requests with fixes to the source code or the manuscript. Your fixes help the next reader.

## The Example Programs

The code lives under `source-code/` in the GitHub repository. Each example is its own [dune](https://dune.build/) project with a build, a program you can run, and a test suite. The examples fall into five groups:

**Language and functional basics.** Pattern matching and variant types, a small `State` module, trace-style debugging, timers with a hard timeout, unit testing with Alcotest, file and console I/O, and command-line programs.

**Math, text, and NLP.** Symbolic differentiation and integration over exact rationals, text cleaning, a small dataframe over CSV data, a Brill part-of-speech tagger, and a natural language toolkit that categorizes text, summarizes it, and finds names.

**Web, data, and services.** HTML scraping, SQLite access, an in-memory RDF store with a SPARQL-style query engine, a DBpedia SPARQL client, a TCP client and server, and web apps built on the Dream server.

**LLM and search clients.** Command-line clients for a local Ollama model, the OpenAI chat API, and the Google Gemini API, plus a client for the Brave Search API.

**Games.** Console blackjack, a contract bridge engine with AI bidding and play (and a web version), and a Go board engine with a self-play agent.

## How to Read This Book

Start with Chapter 1 if you are new to OCaml. If you already write OCaml, skim it for the idioms this book leans on and move on to whatever chapter interests you. Every chapter stands alone, and every example builds and runs with the same three commands: `dune build`, `dune exec`, and `dune runtest`.

## Setup

Install OCaml and dune with [opam](https://opam.ocaml.org/), then add the libraries the examples use:

```bash
opam install dune yojson cohttp-lwt-unix lwt tls-lwt uri \
  alcotest csv lambdasoup caqti caqti-lwt caqti-driver-sqlite3 dream
```

Chapter 1 covers this in more detail. Each example directory also has a `README.md` with the exact commands to build, run, and test it.

## License for the Book Manuscript: Creative Commons

Copyright 2016-2026 Mark Watson. All rights reserved.

You may share this book under the Creative Commons "share and share alike, no modifications, no commercial reuse" license.

## Hire the Author as a Consultant

I am available for short consulting projects. Please see [https://markwatson.com](https://markwatson.com).

## A Short Note on My AI Journey

I have worked on many AI projects since the 1980s: expert system tools for Lisp machines and the Macintosh, commercial neural network tools, natural language systems, medical information systems, AI for video games, and AI for the financial markets. I worked at Google on their Knowledge Graph, and I managed a deep learning team at Capital One, where I was awarded 55 US patents. I enjoy AI programming, and I hope this enthusiasm reaches you.

## Acknowledgements

I produced this book with the [leanpub.com](http://leanpub.com) publishing system, which I recommend to other authors.

**Editor: Carol Watson**
