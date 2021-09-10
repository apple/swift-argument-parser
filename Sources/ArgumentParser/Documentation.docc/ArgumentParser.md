# ``ArgumentParser``

Straightforward, type-safe argument parsing for Swift.

## Overview

By using `ArgumentParser`, you can create a command-line interface tool
by declaring simple Swift types.
Begin by declaring a type that defines
the information that you need to collect from the command line.
Decorate each stored property with one of `ArgumentParser`'s property wrappers,
declare conformance to ``ParsableCommand``,
and implement your command's logic in its `run()` method.

```swift
import ArgumentParser

@main
struct Repeat: ParsableCommand {
    @Argument(help: "The phrase to repeat.")
    var phrase: String

    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?

    mutating func run() throws {
        let repeatCount = count ?? .max
        for _ in 0..<repeatCount {
            print(phrase)
        }
    }
}
```

When a user executes your command, 
the `ArgumentParser` library parses the command-line arguments,
instantiates your command type,
and then either calls your `run()` method or exits with a useful message.

```
$ repeat hello --count 3
hello
hello
hello
$ repeat --help
USAGE: repeat [--count <count>] <phrase>

ARGUMENTS:
  <phrase>                The phrase to repeat.

OPTIONS:
  --count <count>         The number of times to repeat 'phrase'.
  -h, --help              Show help for this command.
$ repeat --count 3
Error: Missing expected argument 'phrase'.
Help:  <phrase>  The phrase to repeat.
Usage: repeat [--count <count>] <phrase>
  See 'repeat --help' for more information.
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:CommandsAndSubcommands>
- ``ParsableCommand``

### Arguments, Options, and Flags

- <doc:DeclaringArguments>
- ``Argument``
- ``Option``
- ``Flag``
- ``OptionGroup``
- ``ParsableArguments``

### Property Customization

- <doc:CustomizingHelp>
- ``ArgumentHelp``
- ``NameSpecification``

### Custom Types

- ``ExpressibleByArgument``
- ``EnumerableFlag``

### Validation and Errors

- <doc:Validation>
- ``ValidationError``
- ``CleanExit``
- ``ExitCode``

### Shell Completion Scripts

- <doc:InstallingCompletionScripts>
- <doc:CustomizingCompletions>
- ``CompletionKind``

### Advanced Topics

- <doc:ManualParsing>
