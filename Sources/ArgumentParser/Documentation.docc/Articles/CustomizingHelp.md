# Customizing Help

Support your users (and yourself) by providing rich help for arguments and commands.

## Overview

You can provide help text when declaring any `@Argument`, `@Option`, or `@Flag` by passing a string literal as the `help` parameter:

```swift
struct Example: ParsableCommand {
    @Flag(help: "Display extra information while processing.")
    var verbose = false

    @Option(help: "The number of extra lines to show.")
    var extraLines = 0

    @Argument(help: "The input file.")
    var inputFile: String?
}
```

Users see these strings in the automatically-generated help screen, which is triggered by the `-h` or `--help` flags, by default:

```
% example --help
USAGE: example [--verbose] [--extra-lines <extra-lines>] <input-file>

ARGUMENTS:
  <input-file>            The input file.

OPTIONS:
  --verbose               Display extra information while processing.
  --extra-lines <extra-lines>
                          The number of extra lines to show. (default: 0)
  -h, --help              Show help information.
```

## Customizing Help for Arguments

You can have more control over the help text by passing an `ArgumentHelp` instance instead. The `ArgumentHelp` type can include an abstract (which is what the string literal becomes), a discussion, a value name to use in the usage string, and a Boolean that indicates whether the argument should be visible in the help screen.

Here's the same command with some extra customization:

```swift
struct Example: ParsableCommand {
    @Flag(help: "Display extra information while processing.")
    var verbose = false

    @Option(help: ArgumentHelp(
        "The number of extra lines to show.",
        valueName: "n"))
    var extraLines = 0

    @Argument(help: ArgumentHelp(
        "The input file.",
        discussion: "If no input file is provided, the tool reads from stdin.",
        valueName: "file"))
    var inputFile: String?
}
```

...and the help screen:

```
USAGE: example [--verbose] [--extra-lines <n>] [<file>]

ARGUMENTS:
  <file>                  The input file.
        If no input file is provided, the tool reads from stdin.

OPTIONS:
  --verbose               Display extra information while processing.
  --extra-lines <n>       The number of extra lines to show. (default: 0)
  -h, --help              Show help information.
```

## Customizing Help for Commands

In addition to configuring the command name and subcommands, as described in [Command and Subcommands](03%20Commands%20and%20Subcommands.md), you can also configure a command's help text by providing an abstract and discussion.

```swift
struct Repeat: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Repeats your input phrase.",
        discussion: """
            Prints to stdout forever, or until you halt the program.
            """)

    @Argument(help: "The phrase to repeat.")
    var phrase: String

    mutating func run() throws {
        while true { print(phrase) }
    }
}
```

The abstract and discussion appear in the generated help screen:

```
% repeat --help
OVERVIEW: Repeats your input phrase.

Prints to stdout forever, or until you halt the program.

USAGE: repeat <phrase>

ARGUMENTS:
  <phrase>                The phrase to repeat.

OPTIONS:
  -h, --help              Show help information.

% repeat hello!
hello!
hello!
hello!
hello!
hello!
hello!
...
```

## Modifying the Help Flag Names

Users can see the help screen for a command by passing either the `-h` or the `--help` flag, by default. If you need to use one of those flags for another purpose, you can provide alternative names when configuring a root command.

```swift
struct Example: ParsableCommand {
    static let configuration = CommandConfiguration(
        helpNames: [.long, .customShort("?")])

    @Option(name: .shortAndLong, help: "The number of history entries to show.")
    var historyDepth: Int

    mutating func run() throws {
        printHistory(depth: historyDepth)
    }
}
```

When running the command, `-h` matches the short name of the `historyDepth` property, and `-?` displays the help screen.

```
% example -h 3
...
% example -?
USAGE: example --history-depth <history-depth>

ARGUMENTS:
  <phrase>                The phrase to repeat.

OPTIONS:
  -h, --history-depth     The number of history entries to show.
  -?, --help              Show help information.
```

When not overridden, custom help names are inherited by subcommands. In this example, the parent command defines `--help` and `-?` as its help names:

```swift
struct Parent: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [Child.self],
        helpNames: [.long, .customShort("?")])

    struct Child: ParsableCommand {
        @Option(name: .shortAndLong, help: "The host the server will run on.")
        var host: String
    }
}
```

The `child` subcommand inherits the parent's help names, allowing the user to distinguish between the host argument (`-h`) and help (`-?`).

```
% parent child -h 192.0.0.0
...
% parent child -?
USAGE: parent child --host <host>

OPTIONS:
  -h, --host <host>       The host the server will run on.
  -?, --help              Show help information.
```

## Hiding Arguments and Commands

You may want to suppress features under development or experimental flags from the generated help screen. You can hide an argument or a subcommand by passing `shouldDisplay: false` to the property wrapper or `CommandConfiguration` initializers, respectively.

`ArgumentHelp` includes a `.hidden` static property that makes it even simpler to hide arguments:

```swift
struct Example: ParsableCommand {
    @Flag(help: .hidden)
    var experimentalEnableWidgets: Bool
}
```

## Generating Help Text Programmatically

The help screen is automatically shown to users when they call your command with the help flag. You can generate the same text from within your program by calling the `helpMessage()` method.

```swift
let help = Repeat.helpMessage()
// `help` matches the output above

let fortyColumnHelp = Repeat.helpMessage(columns: 40)
// `fortyColumnHelp` is the same help screen, but wrapped to 40 columns
```

When generating help text for a subcommand, call `helpMessage(for:)` on the `ParsableCommand` type that represents the root of the command tree and pass the subcommand type as a parameter to ensure the correct display.
