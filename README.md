# Swift Argument Parser

## Usage

Begin by declaring a type that defines the information you need to collect from the command line.
Decorate each stored property with one of `ArgumentParser`'s property wrappers,
and declare conformance to `ParsableCommand`.

```swift
import ArgumentParser

struct Repeat: ParsableCommand {
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter: Bool

    @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
    var count: Int?

    @Argument(help: "The phrase to repeat.")
    var phrase: String
}
```

Next, implement the `run()` method on your type, 
and kick off execution by calling the type's static `main()` method.  
The `ArgumentParser` library parses the command-line arguments,
instantiates your command type, and then either executes your custom `run()` method 
or exits with useful a message.

```swift
extension Repeat {
    func run() throws {
        let repeatCount = count ?? .max

        for i in 1...repeatCount {
            if includeCounter {
                print("\(i): \(phrase)")
            } else {
                print(phrase)
            }
        }
    }
}

Repeat.main()
```

`ArgumentParser` uses your properties' names and type information,
along with the details you provide using property wrappers,
to supply useful error messages and detailed help:

```
$ repeat hello --count 3
hello
hello
hello
$ repeat
Error: Missing required value for argument 'phrase'.
Usage: repeat [--count <count>] [--include-counter] <phrase>
$ repeat --help
USAGE: repeat [--count <count>] [--include-counter] <phrase>

ARGUMENTS:
  <phrase>                The phrase to repeat.

OPTIONS:
  --include-counter       Include a counter with each repetition.
  -c, --count <count>     The number of times to repeat 'phrase'.
  -h, --help              Show help for this command.
```

## Examples

This repository includes a few examples of using the library:

- [`repeat`](Examples/repeat/main.swift) is the example shown above.
- [`roll`](Examples/roll/main.swift) is a simple utility implemented as a straight-line script.
- [`math`](Examples/math/main.swift) is an annotated example of using nested commands and subcommands.

You can also see examples of `ArgumentParser` adoption among Swift project tools:

- [`indexstore-db`](https://github.com/apple/indexstore-db/pull/72) is a simple utility with two commands.
- [`swift-format`](https://github.com/apple/swift-format/pull/154) uses some advanced features, like custom option values and hidden flags.

## Adding `ArgumentParser` as a Dependency

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
```

...and then include `"ArgumentParser"` as a dependency for your executable target:

```swift
.product(name: "ArgumentParser", package: "swift-argument-parser"),
```

> **Note:** Because `ArgumentParser` is under active development,
source-stability is only guaranteed within minor versions (e.g. between `0.0.3` and `0.0.4`).
If you don't want potentially source-breaking package updates,
you can specify your package dependency using `.upToNextMinorVersion(from: "0.0.1")` instead.
