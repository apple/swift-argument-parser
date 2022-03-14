# ``ArgumentParser/ParsableCommand``

`ParsableCommand` types are the basic building blocks for command-line tools built using `ArgumentParser`. To create a command, declare properties using the `@Argument`, `@Option`, and `@Flag` property wrappers, or include groups of options with `@OptionGroup`. Finally, implement your command's functionality in the ``run()-7p2fr`` method.

```swift
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

## Topics

### Essentials

- <doc:CommandsAndSubcommands>
- <doc:CustomizingCommandHelp>

### Implementing a Command's Behavior

- ``run()-7p2fr``
- ``ParsableArguments/validate()-5r0ge``

### Customizing a Command

- ``configuration-35km1``
- ``CommandConfiguration``

### Generating Help Text

- ``helpMessage(for:includeHidden:columns:)``

### Starting the Program

- ``main()``
- ``main(_:)``

### Manually Parsing Input

- ``parseAsRoot(_:)``

