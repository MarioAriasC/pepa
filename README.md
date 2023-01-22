# Pepa

[Ruby](https://www.ruby-lang.org/en/) implementation of
the [Monkey Language](https://monkeylang.org/)

Pepa has many sibling implementations

* Kotlin: [monkey.kt](https://github.com/MarioAriasC/monkey.kt)
* Crystal: [Monyet](https://github.com/MarioAriasC/monyet)
* Scala 3: [Langur](https://github.com/MarioAriasC/langur)

## Status

The book ([Writing An Interpreter In Go](https://interpreterbook.com/)) is fully implemented. Pepa will not have a
compiler implementation

## Commands

Before running the command you must have Ruby 3.1.0 or up installed on your machine

| Script                                       | Description                                                |
|----------------------------------------------|------------------------------------------------------------|
| `rake`                                       | Run tests and rubocop                                      |
| [`./exe/benchmark`](exe/benchmark)           | Run the classic monkey benchmark (`fibonacci(35)`)         |
| [`./exe/benchmark-yjit`](exe/benchmark-yjit) | Run the classic monkey benchmark with JIT(`fibonacci(35)`) |
| [`./exe/pepa`](exe/pepa)                     | Run the Pepa REPL                                          |
