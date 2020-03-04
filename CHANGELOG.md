# CHANGELOG

<!-- 
Add new items at the end of the relevant section under **Unreleased**.
-->

This project follows semantic versioning. While still in major version `0`,
source-stability is only guaranteed within minor versions (e.g. between
`0.0.3` and `0.0.4`). If you want to guard against potentially source-breaking
package updates, you can specify your package dependency using
`.upToNextMinor(from: "0.0.1")` as the requirement.

## [Unreleased]

### Additions

- The `EX_USAGE` exit code is now used for validation errors.
- The parser provides near-miss suggestions when a user provides an unknown
  option.
- `ArgumentParser` now builds on Windows.
- You can throw an `ExitCode` error to exit without printing any output.

### Fixes

- Cleaned up a wide variety of documentation typos and shortcomings.
- Improved different kinds of error messages:
  - Duplicate exclusive flags now show the duplicated arguments.
  - Subcommand validation errors print the correct usage string.
- In the help screen:
  - Removed the extra space before the default value for arguments without
    descriptions.
  - Removed the default value note when the default value is an empty string.
  - Default values are now shown for Boolean options.

## [0.0.1] - 2020-02-27

- `ArgumentParser` initial release.




[Unreleased]: https://github.com/apple/swift-argument-parser/compare/0.0.1...HEAD
[0.0.1]: https://github.com/apple/swift-argument-parser/releases/tag/0.0.1

