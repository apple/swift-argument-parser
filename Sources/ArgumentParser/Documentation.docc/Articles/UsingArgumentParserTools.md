# Using ArgumentParser Tools

Learn how to provide input to command-line tools built with `ArgumentParser`.

## Overview

Tools built with `ArgumentParser` can accept positional arguments, named
options, and flags. The tool's help screen describes the inputs it supports;
run a tool with the `--help` flag to display it.

### Separating Options from Positional Arguments

Use the `--` option terminator when a positional value starts with a dash and
could otherwise be interpreted as an option or flag. A tool stops recognizing
options and flags after `--` and treats every remaining input as positional.
The terminator itself isn't included in the parsed values:

```
% example --verbose -- file1.swift file2.swift --other
Verbose: true, files: ["file1.swift", "file2.swift", "--other"]
```

This convention also lets you pass a positional value that has the same
spelling as a declared option or flag. In the following example, `--verbose`
is stored in `files` instead of setting the `verbose` flag:

```
% example -- --verbose file1.swift
Verbose: false, files: ["--verbose", "file1.swift"]
```
