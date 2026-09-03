# Experimental Features

Learn about ArgumentParser's experimental features.

## Overview

Command-line programs built using `ArgumentParser` may include some built-in experimental features, available with the prefix `--experimental`. These features should not be considered stable while still prefixed, as future releases may change their behavior or remove them.

If you have any feedback on experimental features, please [open a GitHub issue][issue].

### List of Experimental Features

| Name | Description | related PRs | Version |
| ------------- | ------------- | ------------- | ------------- |
| `--experimental-dump-help`  | Dumps command/argument/help information as JSON | [#310][] [#335][] | 0.5.0 or newer |
| `--experimental-dump-arguments-source-location`  | Dumps the parsed argument tree with each value's source location (file:line for response-file args, `argv[N]` for command-line args). Accepts `=text` (default) or `=json`. | [#909][] | Unreleased |


[#310]: https://github.com/apple/swift-argument-parser/pull/310
[#335]: https://github.com/apple/swift-argument-parser/pull/335
[issue]: https://github.com/apple/swift-argument-parser/issues/new/choose
[#909]: https://github.com/apple/swift-argument-parser/pull/909
