# Response Files

Use response files to store command-line arguments in files for reuse and to handle commands with many arguments.

## Overview

Response files allow you to store command-line arguments in text files and reference them using the `@filename` syntax. This feature is particularly useful for:

- Commands with many arguments that would be unwieldy on the command line
- Reusable argument sets for different configurations
- Build systems and automation scripts
- Avoiding command-line length limitations

Swift Argument Parser automatically supports response files for all commands (`ParsableCommand` and `AsyncParsableCommand`) without requiring any code changes.

## Basic Usage

To use a response file, prefix the filename with `@`:

```bash
mycommand @args.txt --verbose
```

This expands the contents of `args.txt` and includes them in the command-line arguments.

### Response File Format

Response files support multiple formats:

#### One Argument Per Line
```
--input
input.txt
--output
output.txt
--verbose
```

#### Space-Separated Arguments
```
--input input.txt --output output.txt --verbose
```

#### Mixed Format
```
--input input.txt
--output output.txt
--verbose --count 42
```

## Advanced Features

### Quoted Arguments

Response files support quoted arguments for values containing spaces:

```
--input "file with spaces.txt"
--message 'Hello, world!'
--path "/Users/username/My Documents/file.txt"
```

### Comments

Use `#` to add comments to response files:

```
# Configuration for production build
--release
--optimize-for-size
--output production.app  # Output directory
```

### Equals Format

Arguments can use the equals format:

```
--input=input.txt
--output=output.txt
--count=42
```

### Nested Response Files

Response files can reference other response files:

```
# main.txt
@common-options.txt
--specific-flag
@environment-config.txt
```

```
# common-options.txt
--verbose
--log-level debug
```

```
# environment-config.txt
--api-endpoint https://api.example.com
--timeout 30
```

## Error Handling

Swift Argument Parser provides clear error messages for response file issues:

### File Not Found
```
Error: Response file not found: args.txt
```

### Malformed Content
```
Error: Malformed content in response file 'args.txt': Line 3: Unclosed quote in argument
```

### Recursive Inclusion
```
Error: Recursive response file inclusion detected: /path/to/recursive.txt
```

### Maximum Nesting Depth
```
Error: Maximum nesting depth (32) exceeded for response files
```

## Examples

### Build Configuration

Create different response files for different build configurations:

```bash
# debug.txt
--configuration debug
--enable-assertions
--debug-info-format dwarf
--output debug-build

# release.txt
--configuration release
--optimize-for-speed
--strip-debug-symbols
--output release-build
```

Use them with your build command:

```bash
myBuild @debug.txt
myBuild build @release.txt
```

### Testing with Multiple Inputs

```bash
# test-inputs.txt
--input test1.swift
--input test2.swift
--input test3.swift
--output-dir test-results
--format junit
--parallel
```

```bash
myTest @test-inputs.txt
```

### Database Migration

```bash
# migration.txt
--database-url postgresql://localhost/myapp
--migration-dir migrations/
--environment production
--backup-before-migration
--verbose
```

```bash
migrate @migration.txt
```

## Mixing Response Files with Command-Line Arguments

You can combine response files with regular command-line arguments:

```bash
mycommand @base-config.txt --override-setting value @additional-flags.txt
```

Arguments are processed in order, so later arguments can override earlier ones:

```bash
# If base-config.txt contains "--count 10"
mycommand @base-config.txt --count 20  # Final count will be 20
```

## Literal At Signs

To use a literal `@` character in an argument, escape it with `@@`:

```bash
mycommand --username @@admin  # Passes "@admin" as the username
```

In response files:

```
--message @@important: This is critical
--email user@@example.com
```

## Performance Considerations

Response files are processed efficiently:

- Files are read once and cached during parsing
- Large response files (thousands of arguments) are supported
- Nested files are processed with recursion detection to prevent infinite loops
- Memory usage scales linearly with the total number of arguments
