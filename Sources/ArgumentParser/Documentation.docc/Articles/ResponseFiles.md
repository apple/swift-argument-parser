# Response Files

Use response files to store command-line arguments in files for reuse and to handle commands with many arguments.

## Overview

Response files allow you to store command-line arguments in text files and reference them using the `@filename` syntax. This feature is particularly useful for:

- Commands with many arguments that would be unwieldy on the command line
- Reusable argument sets for different configurations
- Build systems and automation scripts
- Avoiding command-line length limitations

Swift Argument Parser response file support is opt-in per command. To
enable it, override the `responseFilePrefix` static property on your
root `ParsableCommand` (or `AsyncParsableCommand`) with the character
that should introduce a response-file reference. The default value is
`nil`, meaning response files are disabled and any argument that would
otherwise look like `@file` is passed through as a literal value.

## Basic Usage

Enable response files by declaring a prefix on the root command:

```swift
struct MyTool: ParsableCommand {
    static var responseFilePrefix: Character? { "@" }
    // ...
}
```

Then reference a response file on the command line by prefixing the
filename with the character you chose (`@` in this example):

```bash
mycommand @args.txt --verbose
```

This expands the contents of `args.txt` and includes them in the command-line arguments.

### Customizing the Response File Prefix

The `@` character is the most widely used convention (for example,
`clang @args.txt`), but any single character works. If `@` conflicts
with your command's own argument syntax, pick a different character
instead. The root command's prefix applies to the entire invocation,
including subcommand parsing.

```swift
struct MyTool: ParsableCommand {
    static var responseFilePrefix: Character? { "+" }
    // ...
}
```

With this configuration, `mytool +args.txt` expands `args.txt` as a
response file, while `mytool @foo` is passed through as a literal
argument. The same doubling escape convention applies to the customized
prefix — `++value` inside a response file produces the literal `+value`,
mirroring the, implied response file prefix, `@@` → `@` behavior
described in [Literal At Signs](#literal-at-signs).

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

Response files support quoted arguments for values containing spaces, special
characters, or characters that would otherwise be interpreted as part of the
response-file syntax (like `#` starting a comment).

```
--input "file with spaces.txt"
--message 'Hello, world!'
--path "/Users/username/My Documents/file.txt"
```

#### Which quote style to use

Both double quotes (`"..."`) and single quotes (`'...'`) are supported, and
they behave differently:

- **Double quotes (`"..."`)** — the *interpreting* quote. Escape sequences
  inside the quotes are processed (see below), and the quote character can
  itself be escaped with `\"`.
- **Single quotes (`'...'`)** — the *literal* quote. Everything between the
  quotes is taken verbatim; there is no escape processing. Use single quotes
  when the value contains backslashes or double quotes that you want to
  preserve exactly as written.
- **Nested quotes** — a double-quoted string may contain unescaped single
  quotes, and a single-quoted string may contain unescaped double quotes.
  Only the outer quote style needs to be escaped or switched.

Examples:

```
# Double-quoted: backslash escapes are processed.
--message "line one\nline two"        # decoded as "line one<LF>line two"
--path    "C:\\Users\\Bob\\file.txt"  # decoded as "C:\Users\Bob\file.txt"
--quote   "she said \"hi\""           # decoded as 'she said "hi"'

# Single-quoted: nothing is processed. Use this when you want backslashes
# to reach the tool verbatim.
--regex   'foo\d+\.bar'               # tool receives 'foo\d+\.bar' unchanged
--json    '{"key": "value"}'          # tool receives '{"key": "value"}'

# Mixing quote styles avoids escaping.
--sql     "SELECT * FROM 'users'"
--label   'the "special" one'
```

#### Recognized escape sequences (double quotes only)

Inside double-quoted arguments, the following backslash escapes are
recognized:

| Escape | Decoded |
|--------|---------|
| `\n`   | newline |
| `\t`   | tab     |
| `\r`   | carriage return |
| `\\`   | a single `\` |
| `\"`   | a single `"` |

Any other `\x` sequence (for an unrecognized `x`) is preserved verbatim as
`\x`, so accidental escape characters don't silently disappear. Backslashes
inside single-quoted arguments are always literal.

#### Whitespace handling

Whitespace inside a quoted value (of either style) is preserved and treated
as part of the value — it does not split the argument. Outside of quotes,
runs of spaces and tabs separate arguments as usual.

```
# Both --title and --tags receive a single value each.
--title "Grand Total"
--tags  '  keep   the   spaces  '
```

#### `@file` inside a quoted argument

The response-file prefix is only interpreted when it starts an *unquoted*
token. A quoted string that happens to begin with `@` is passed through as a
literal value (this differs from the `@@`-escape mechanism described in
[Literal At Signs](#literal-at-signs), which only applies to unquoted
tokens):

```
--username "@admin"    # value is "@admin"; no file is opened
--pattern  '@daily'    # value is "@daily"; single quotes protect it too
```

#### Common mistakes

- **Unclosed quotes** are implicitly closed at end-of-file: whatever
  content follows the opening quote — including any intervening
  newlines — becomes part of a single token. Watch out for this: a
  stray `"` or `'` will silently gobble everything up to the end of the
  file (or the matching quote) into one argument.
- **Mismatched quotes** (opening with `"` and closing with `'`, or vice
  versa) behave the same way — the second quote is treated as literal
  content inside the still-open segment.
- **Escaping in the wrong style** — writing `'a\nb'` produces the literal
  four characters `a\nb`, not `a<newline>b`. Use double quotes if you want
  the newline.

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

Inside a response file, you can also protect a leading `@` by wrapping the
value in quotes — see [Quoted Arguments](#quoted-arguments) for details on
how quoted tokens beginning with `@` are passed through verbatim.

## Performance Considerations

Response files are processed efficiently:

- Files are read once and cached during parsing
- Large response files (thousands of arguments) are supported
- Nested files are processed with recursion detection to prevent infinite loops
- Memory usage scales linearly with the total number of arguments
