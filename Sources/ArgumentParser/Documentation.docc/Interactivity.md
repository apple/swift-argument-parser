# Interactivity

The `canInteract()` in `CommandParser` can try to fix errors such as `.missingValueForOption` or `.noValue` by interacting with the user.

## Overview

Let's take the modified `Repeat` as an example:

```swift
@main
struct Repeat: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int

    @Flag(help: "Include a counter with each repetition.")
    var includeCounter = false

    @Argument(help: "The phrase to repeat.")
    var phrase: String

    mutating func run() throws { ... }
}
```

In the absence of interactive mode, if the user forgets option `count` in the initial command, the program will throw the following error and exit:

```
% repeat hello
Error: Missing expected argument '--count <count>'
Help:  --count <count>  The number of times to repeat 'phrase'.
Usage: repeat --count <count> [--include-counter] <phrase>
  See 'repeat --help' for more information.
```

While the interactive mode can prompt for the required arguments not given in the beginning, then the new input will be used for partial initialization, and eventually the program will run successfully:

```
% repeat hello
? Please enter 'count': 2
hello
hello
```
## Test

Here are some boundary conditions that can be used for testing:

```
// The value for option is missing.
% repeat hello --count
```

```
// The value for option in the middle is missing.
% repeat hello --count --include-counter
```

```
// More than one parameter is missing.
% repeat --include-counter
```
