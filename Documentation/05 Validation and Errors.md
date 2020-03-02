# Validation and Errors

Provide helpful feedback to users when things go wrong.

## Validating Command-Line Input

While `ArgumentParser` validates that the inputs given by your user match the requirements and types that you define in each command, there are some requirements that can't easily be described in Swift's type system, such as the number of elements in an array, or an expected integer value.

To validate your commands properties after parsing, implement the `validate()` method on any `ParsableCommand` or `ParsableArguments` type. Throwing an error from the `validate()` method causes the program to print a message to standard error and exit with an error code, preventing the `run()` method from being called with invalid inputs.

Here's a command that prints out one or more random elements from the list you provide. Its `validate()` method catches three different errors that a user can make and throws a relevant error for each one. 

```swift
struct Select: ParsableCommand {
    @Option(default: 1)
    var count: Int
    
    @Argument()
    var elements: [String]

    mutating func validate() throws {
        guard count >= 1 else {
            throw ValidationError("Please specify a 'count' of at least 1.")
        }

        guard !elements.isEmpty else {
            throw ValidationError("Please provide at least one element to choose from.")
        }
 
        guard count <= elements.count else {
            throw ValidationError("Please specify a 'count' less than the number of elements.")
        }
    }
    
    func run() {
        print(elements.shuffled().prefix(count).joined(separator: "\n"))
    }
}
```

When you provide useful error messages, they can guide new users to success with your command-line tool!

```
% select
Error: Please provide at least one element to choose from.
Usage: select [--count <count>] [<elements> ...]
% select --count 2 hello
Error: Please specify a 'count' less than the number of elements.
Usage: select [--count <count>] [<elements> ...]
% select --count 0 hello hey hi howdy
Error: Please specify a 'count' of at least 1.
Usage: select [--count <count>] [<elements> ...]
% select --count 2 hello hey hi howdy
howdy
hey
```

## Handling Post-Validation Errors

The `ValidationError` type is a special `ArgumentParser` error — a validation error's message is always accompanied by an appropriate usage string. You can throw other errors, from either the `validate()` or `run()` method to indicate that something has gone wrong that isn't validation-specific. Errors that conform to `CustomStringConvertible` or `LocalizedError` provide the best experience for users.

```swift
struct LineCount: ParsableCommand {
    @Argument() var file: String
    
    func run() throws {
        let contents = try String(contentsOfFile: file, encoding: .utf8)
        let lines = contents.split(separator: "\n")
        print(lines.count)
    }
}
```

The throwing `String(contentsOfFile:encoding:)` initializer fails when the user specifies an invalid file. `ArgumentParser` prints its error message to standard error and exits with an error code.

```
% line-count file1.swift
37
% line-count non-existing-file.swift
Error: The file “non-existing-file.swift” couldn’t be opened because
there is no such file.
```

If you print your error output yourself, you still need to throw an error from `validate()` or `run()`, so that your command exits with the appropriate exit code. To avoid printing an extra error message, use the `ExitCode` error, which has static properties for success, failure, and validation errors, or lets you specify a specific exit code.

```swift
struct RuntimeError: Error, CustomStringConvertible {
    var description: String
}

struct Example: ParsableCommand {
    @Argument() var inputFile: String
    
    func run() throws {
        if !ExampleCore.processFile(inputFile) {
            // ExampleCore.processFile(_:) prints its own errors
            // and returns `false` on failure.
            throw ExitCode.failure
        }
    }
}
```
