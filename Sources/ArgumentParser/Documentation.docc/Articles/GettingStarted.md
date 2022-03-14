# Getting Started with ArgumentParser

Learn to set up and customize a simple command-line tool.

## Overview

This guide walks through building an example command. You'll learn about the different tools that `ArgumentParser` provides for defining a command's options, customizing the interface, and providing help text for your user.

## Adding ArgumentParser as a Dependency

Let's write a tool called `count` that reads an input file, counts the words, and writes the result to an output file.

First, we need to add `swift-argument-parser` as a dependency to our package, 
and then include `"ArgumentParser"` as a dependency for our executable target.
Our "Package.swift" file ends up looking like this:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Count",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "count",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]),
    ]
)
```

## Building Our First Command

Once we've built the `count` tool, we'll be able to run it like this:

```
% count readme.md readme.counts
Counting words in 'readme.md' and writing the result into 'readme.counts'.
```

We'll define the initial version of the command as a type that conforms to the `ParsableCommand` protocol:

```swift
import ArgumentParser

@main
struct Count: ParsableCommand {
    @Argument var inputFile: String
    @Argument var outputFile: String
    
    mutating func run() throws {
        print("""
            Counting words in '\(inputFile)' \
            and writing the result into '\(outputFile)'.
            """)
            
        // Read 'inputFile', count the words, and save to 'outputFile'.
    }
}
```

In the code above, the `inputFile` and `outputFile` properties use the `@Argument` property wrapper. `ArgumentParser` uses this wrapper to denote a positional command-line input — because `inputFile` is specified first in the `Count` type, it's the first value read from the command line, and `outputFile` is the second.

We've implemented the command's logic in its `run()` method. Here, we're printing out a message confirming the names of the files the user gave. (You can find a full implementation of the completed command at the end of this guide.)

Finally, you designate the `Count` command as the program's entry point by applying the `@main` attribute. When running your command, the `ArgumentParser` library parses the command-line arguments, verifies that they match up with what we've defined in `Count`, and either calls the `run()` method or exits with a helpful message.


## Working with Named Options

Our `count` tool may have a usability problem — it's not immediately clear whether a user should provide the input file first, or the output file. Instead of using positional arguments for our two inputs, let's specify that they should be labeled options:

```
% count --input-file readme.md --output-file readme.counts
Counting words in 'readme.md' and writing the result into 'readme.counts'.
```

We do this by using the `@Option` property wrapper instead of `@Argument`:

```swift
struct Count: ParsableCommand {
    @Option var inputFile: String
    @Option var outputFile: String
    
    mutating func run() throws {
        print("""
            Counting words in '\(inputFile)' \
            and writing the result into '\(outputFile)'.
            """)
            
        // Read 'inputFile', count the words, and save to 'outputFile'.
    }
}
```

The `@Option` property wrapper denotes a command-line input that looks like `--name <value>`, deriving its name from the name of your property. 

This interface has a trade-off for the users of our `count` tool: With `@Argument`, users don't need to type as much, but they have to remember whether to provide the input file or the output file first. Using `@Option` makes the user type a little more, but the distinction between values is explicit. Options are order-independent, as well, so the user can name the input and output files in either order:

```
% count --output-file readme.counts --input-file readme.md
Counting words in 'readme.md' and writing the result into 'readme.counts'.
```

## Adding a Flag

Next, we want to add a `--verbose` flag to our tool, and only print the message if the user specifies that option:

```
% count --input-file readme.md --output-file readme.counts
(no output)
% count --verbose --input-file readme.md --output-file readme.counts
Counting words in 'readme.md' and writing the result into 'readme.counts'.
```

Let's change our `Count` type to look like this:

```swift
struct Count: ParsableCommand {
    @Option var inputFile: String
    @Option var outputFile: String
    @Flag var verbose = false
    
    mutating func run() throws {
        if verbose {
            print("""
                Counting words in '\(inputFile)' \
                and writing the result into '\(outputFile)'.
                """)
        }
 
        // Read 'inputFile', count the words, and save to 'outputFile'.
    }
}
```

The `@Flag` property wrapper denotes a command-line input that looks like `--name`, deriving its name from the name of your property. Flags are most frequently used for Boolean values, like the `verbose` property here.


## Using Custom Names

We can customize the names of our options and add an alternative to the `verbose` flag so that users can specify `-v` instead of `--verbose`. The new interface will look like this:

```
% count -v -i readme.md -o readme.counts
Counting words in 'readme.md' and writing the result into 'readme.counts'.
% count --input readme.md --output readme.counts -v
Counting words in 'readme.md' and writing the result into 'readme.counts'.
% count -o readme.counts -i readme.md --verbose
Counting words in 'readme.md' and writing the result into 'readme.counts'.
```

Customize the input names by passing `name` parameters to the `@Option` and `@Flag` initializers:

```swift
struct Count: ParsableCommand {
    @Option(name: [.short, .customLong("input")])
    var inputFile: String

    @Option(name: [.short, .customLong("output")])
    var outputFile: String

    @Flag(name: .shortAndLong)
    var verbose = false
    
    mutating func run() throws { ... }
}
```

The default name specification is `.long`, which uses a property's name with a two-dash prefix. `.short` uses only the first letter of a property's name with a single-dash prefix, and allows combining groups of short options. You can specify custom short and long names with the `.customShort(_:)` and `.customLong(_:)` methods, respectively, or use the combined `.shortAndLong` property to specify the common case of both the short and long derived names.

## Providing Help

`ArgumentParser` automatically generates help for any command when a user provides the `-h` or `--help` flags:

```
% count --help
USAGE: count --input <input> --output <output> [--verbose]

OPTIONS:
  -i, --input <input>      
  -o, --output <output>    
  -v, --verbose            
  -h, --help              Show help information.
```

This is a great start — you can see that all the custom names are visible, and the help shows that values are expected for the `--input` and `--output` options. However, our custom options and flag don't have any descriptive text. Let's add that now by passing string literals as the `help` parameter:

```swift
struct Count: ParsableCommand {
    @Option(name: [.short, .customLong("input")], help: "A file to read.")
    var inputFile: String

    @Option(name: [.short, .customLong("output")], help: "A file to save word counts to.")
    var outputFile: String

    @Flag(name: .shortAndLong, help: "Print status updates while counting.")
    var verbose = false

    mutating func run() throws { ... }
}
```

The help screen now includes descriptions for each parameter:

```
% count -h
USAGE: count --input <input> --output <output> [--verbose]

OPTIONS:
  -i, --input <input>     A file to read. 
  -o, --output <output>   A file to save word counts to. 
  -v, --verbose           Print status updates while counting. 
  -h, --help              Show help information.

```

## The Complete Utility

As promised, here's the complete `count` command, for your experimentation:

```swift
import ArgumentParser
import Foundation

@main
struct Count: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Word counter.")
    
    @Option(name: [.short, .customLong("input")], help: "A file to read.")
    var inputFile: String

    @Option(name: [.short, .customLong("output")], help: "A file to save word counts to.")
    var outputFile: String

    @Flag(name: .shortAndLong, help: "Print status updates while counting.")
    var verbose = false

    mutating func run() throws {
        if verbose {
            print("""
                Counting words in '\(inputFile)' \
                and writing the result into '\(outputFile)'.
                """)
        }
 
        guard let input = try? String(contentsOfFile: inputFile) else {
            throw RuntimeError("Couldn't read from '\(inputFile)'!")
        }
        
        let words = input.components(separatedBy: .whitespacesAndNewlines)
            .map { word in
                word.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    .lowercased()
            }
            .compactMap { word in word.isEmpty ? nil : word }
        
        let counts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted(by: { $0.value > $1.value })
        
        if verbose {
            print("Found \(counts.count) words.")
        }
        
        let output = counts.map { word, count in "\(word): \(count)" }
            .joined(separator: "\n")
        
        guard let _ = try? output.write(toFile: outputFile, atomically: true, encoding: .utf8) else {
            throw RuntimeError("Couldn't write to '\(outputFile)'!")
        }
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}
```
