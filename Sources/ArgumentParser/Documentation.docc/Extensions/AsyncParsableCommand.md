# ``ArgumentParser/AsyncParsableCommand``

To use `async`/`await` code in your commands' `run()` method implementations, follow these steps:

1. For the root command in your command-line tool, declare conformance to `AsyncParsableCommand`, even if that command doesn't use asynchronous code.
2. Apply the `@main` attribute to the root command. (Note: If your root command is in a `main.swift` file, rename the file to the name of the command.)
3. For any command that needs to use asynchronous code, declare conformance to `AsyncParsableCommand` and mark the `run()` method as `async`. No changes are needed for commands that don't use asynchronous code.


### Usage in Swift 5.5

In Swift 5.5, you need to declare a separate, standalone type as your asynchronous `@main` entry point. Instead of designating your root command as `@main`, as described above, use the code snippet below, replacing the placeholder with the name of your own root command. Otherwise, follow the steps above to use `async`/`await` code within your commands' `run()` methods.

```swift
@main struct AsyncMain: AsyncMainProtocol {
    typealias Command = <#RootCommand#>
}
```

## Topics

### Implementing a Command's Behavior

- ``run()``

### Starting the Program

- ``main()``
- ``AsyncMainProtocol``

