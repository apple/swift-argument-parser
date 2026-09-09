# Customizing Help for Commands

Define your command's abstract, extended discussion, or usage string, and set the flags used to invoke the help display.

## Overview

In addition to configuring the command name and subcommands, as described in <doc:CommandsAndSubcommands>, you can also configure a command's help text by providing an abstract, discussion, or custom usage string.

```swift
struct Repeat: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Repeats your input phrase.",
        usage: """
            repeat <phrase>
            repeat --count <count> <phrase>
            """,
        discussion: """
            Prints to stdout forever, or until you halt the program.
            """)

    @Argument(help: "The phrase to repeat.")
    var phrase: String

    @Option(help: "How many times to repeat.")
    var count: Int? = nil

    mutating func run() throws {
        for _ in 0..<(count ?? 2) {
            print(phrase) 
        }
    }
}
```

The customized components now appear in the generated help screen:

```
% repeat --help
OVERVIEW: Repeats your input phrase.

Prints to stdout forever, or until you halt the program.

USAGE: repeat <phrase>
       repeat --count <count> <phrase>

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

### Adding a Banner Inherited by Subcommands

An abstract and discussion describe a single command. To show information that applies to your whole tool — a copyright notice, for example — pass `helpBanner` to the root command's ``CommandConfiguration``. The banner appears above the overview, and every subcommand inherits it.

```swift
struct Nodectl: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage nodes and collect diagnostics.",
        helpBanner: "Acme Corp. Copyright 1234",
        subcommands: [Probe.self])

    struct Probe: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Probe nodes for health and topology.")
    }
}
```

The banner is shown for the root command and for the subcommand, without being declared twice:

```
% nodectl --help
Acme Corp. Copyright 1234

OVERVIEW: Manage nodes and collect diagnostics.

USAGE: nodectl <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  probe                   Probe nodes for health and topology.

  See 'nodectl help <subcommand>' for detailed help.

% nodectl probe --help
Acme Corp. Copyright 1234

OVERVIEW: Probe nodes for health and topology.

USAGE: nodectl probe

OPTIONS:
  -h, --help              Show help information.
```

Inheritance follows the same rule as `helpNames`: a command with no `helpBanner` of its own uses the banner of its closest ancestor that declares one. A subcommand can declare a different banner to replace the inherited one, or declare the empty string to suppress it:

```swift
struct Internal: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "An internal command with no banner.",
        helpBanner: "")
}
```

Unlike `abstract` and `discussion`, a banner is printed verbatim and is never wrapped to the width of the terminal, so multi-line banners and ASCII art render exactly as written. If you want a long single-line banner to wrap, insert the line breaks yourself.

Banners appear wherever the help screen is shown — for the help flags, the `help` subcommand, and when a user runs a command that only groups subcommands. They do not appear in the short usage message printed when a user passes invalid arguments.

### Modifying the Help Flag Names

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
nmap -v -sS -O 10.2.2.2
sshnuke 10.2.2.2 -rootpw="Z1ON0101"
ssh 10.2.2.2 -l root
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

### Hiding Commands

You may not want to show every one of your command as part of your command-line interface. To render a command invisible (but still usable), pass `shouldDisplay: false` to the ``CommandConfiguration`` initializer.

### Generating Help Text Programmatically

The help screen is automatically shown to users when they call your command with the help flag. You can generate the same text from within your program by calling the `helpMessage()` method.

```swift
let help = Repeat.helpMessage()
// `help` matches the output above

let fortyColumnHelp = Repeat.helpMessage(columns: 40)
// `fortyColumnHelp` is the same help screen, but wrapped to 40 columns
```

When generating help text for a subcommand, call `helpMessage(for:)` on the `ParsableCommand` type that represents the root of the command tree and pass the subcommand type as a parameter to ensure the correct display.
