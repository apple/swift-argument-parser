# Completion Scripts

Generate customized completion scripts for your shell of choice.

## Generating and Installing Completion Scripts

Command-line tools that you build with `ArgumentParser` include a built-in option for generating completion scripts, with support for Bash and Z shell. To generate completions, run your command with the `--generate-completion-script` flag to generate completions for the autodetected shell, or with a value to generate completions for a specific shell.

```
$ example --generate-completion-script bash
#compdef example
local context state state_descr line
_example_commandname="example"
typeset -A opt_args

_example() {
    integer ret=1
    local -a args
    ...
}

_example
```

The correct method of installing a completion script depends on your shell and your configuration.

### Installing Zsh Completions

If you have [`oh-my-zsh`](https://ohmyz.sh) installed, you already have a directory of automatically loading completion scripts — `.oh-my-zsh/completions`. Copy your new completion script to that directory.

```
$ example --generate-completion-script zsh > ~/.oh-my-zsh/completions/_example
```

> Your completion script must have the following filename format: `_example`.

Without `oh-my-zsh`, you'll need to add a path for completion scripts to your function path, and turn on completion script autoloading. First, add these lines to `~/.zshrc`:

```
fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit
```

Next, create a directory at `~/.zsh/completion` and copy the completion script to the new directory.

### Installing Bash Completions

If you have [`bash-completion`](https://github.com/scop/bash-completion) installed, you can just copy your new completion script to the `/usr/local/etc/bash_completion.d` directory.

Without `bash-completion`, you'll need to source the completion script directly. Copy it to a directory such as `~/.bash_completions/`, and then add the following line to `~/.bash_profile` or `~/.bashrc`:

```
source ~/.bash_completions/example.bash
```

## Customizing Completions

`ArgumentParser` provides default completions for any types that it can. For example, an `@Option` property that is a `CaseIterable` type will automatically have the correct values as completion suggestions.

When declaring an option or argument, you can customize the completions that are offered by specifying a `CompletionKind`. With this completion kind you can specify that the value should be a file, a directory, or one of a list of strings:

```swift
struct Example: ParsableCommand {
    @Option(help: "The file to read from.", completion: .file())
    var input: String

    @Option(help: "The output directory.", completion: .directory)
    var outputDir: String

    @Option(help: "The preferred file format.", completion: .list(["markdown", "rst"]))
    var format: String

    enum CompressionType: String, CaseIterable, ExpressibleByArgument {
        case zip, gzip
    }

    @Option(help: "The compression type to use.")
    var compression: CompressionType
}
```

The generated completion script will suggest only file names for the `--input` option, only directory names for `--output-dir`, and only the strings `markdown` and `rst` for `--format`. The `--compression` option uses the default completions for a `CaseIterable` type, so the completion script will suggest `zip` and `gzip`.

You can define the default completion kind for custom `ExpressibleByArgument` types by implementing `static var defaultCompletionKind: CompletionKind`. For example, any arguments or options with this `File` type will automatically use files for completions:

```swift
struct File: Hashable, ExpressibleByArgument {
    var path: String
    
    init?(argument: String) {
        self.path = argument
    }
    
    static var defaultCompletionKind: CompletionKind {
        .file()
    }
}
```

For even more control over the suggested completions, you can specify a function that will be called during completion by using the `.custom` completion kind.

```swift
func listExecutables(_ arguments: [String]) -> [String] {
    // Generate the list of executables in the current directory
}

struct SwiftRun {
    @Option(help: "The target to execute.", completion: .custom(listExecutables))
    var target: String?
}
```

In this example, when a user requests completions for the `--target` option, the completion script runs the `SwiftRun` command-line tool with a special syntax, calling the `listExecutables` function with an array of the arguments given so far.
