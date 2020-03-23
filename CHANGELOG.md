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

*No changes yet.*

## [0.0.4] - 2020-03-23

### Fixes

- Removed usage of 5.2-only syntax.

## [0.0.3] - 2020-03-22

### Additions

- You can specify the `.unconditionalRemaining` parsing strategy for arrays of
  positional arguments to accept dash-prefixed input, like
  `example --one two -three`.
- You can now provide a default value for a positional argument.
- You can now customize the display of default values in the extended help for
  an `ExpressibleByArgument` type.
- You can call the static `exitCode(for:)` method on any command to retrieve the
  exit code for a given error.

### Fixes

- Supporting targets are now prefixed to prevent conflicts with other libraries.
- The extension providing `init?(argument:)` to `RawRepresentable` types is now
  properly constrained.
- The parser no longer treats passing the same exclusive flag more than once as
  an error.
- `ParsableArguments` types that are declared as `@OptionGroup()` properties on
  commands can now also be declared on subcommands. Previosuly, the parent 
  command's declaration would prevent subcommands from seeing the user-supplied 
  arguments.
- Default values are rendered correctly for properties with `Optional` types.
- The output of help requests is now printed during the "exit" phase of execution, 
  instead of during the "run" phase.
- Usage strings now correctly show that optional positional arguments aren't 
  required.
- Extended help now omits extra line breaks when displaying arguments or commands
  with long names that don't provide help text.

The 0.0.3 release includes contributions from [compnerd], [elliottwilliams],
[glessard], [griffin-stewie], [iainsmith], [Lantua], [miguelangel-dev],
[natecook1000], [sjavora], and [YuAo]. Thank you!

## [0.0.2] - 2020-03-06

### Additions

- The `EX_USAGE` exit code is now used for validation errors.
- The parser provides near-miss suggestions when a user provides an unknown
  option.
- `ArgumentParser` now builds on Windows.
- You can throw an `ExitCode` error to exit without printing any output.
- You can now create optional Boolean flags with inversions that default to 
  `nil`:
  ```swift
  @Flag(inversion: .prefixedNo) var takeMyShot: Bool?
  ```
- You can now specify exclusivity for case-iterable flags and for Boolean flags
  with inversions.

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
  - Case-iterable flags are now grouped correctly.
  - Case-iterable flags with default values now show the default value.
  - Arguments from parent commands that are included via `@OptionGroup` in 
    subcommands are no longer duplicated.
- Case-iterable flags created with the `.chooseFirst` exclusivity parameter now 
  correctly ignore additional flags.

The 0.0.2 release includes contributions from [AliSoftware], [buttaface], 
[compnerd], [dduan], [glessard], [griffin-stewie], [IngmarStein], 
[jonathanpenn], [klaaspieter], [natecook1000], [Sajjon], [sjavora], 
[Wildchild9], and [zntfdr]. Thank you!

## [0.0.1] - 2020-02-27

- `ArgumentParser` initial release.


<!-- Link references for releases -->

[Unreleased]: https://github.com/apple/swift-argument-parser/compare/0.0.4...HEAD
[0.0.4]: https://github.com/apple/swift-argument-parser/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/apple/swift-argument-parser/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/apple/swift-argument-parser/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/apple/swift-argument-parser/releases/tag/0.0.1

<!-- Link references for contributors -->

[AliSoftware]: https://github.com/apple/swift-argument-parser/commits?author=AliSoftware
[buttaface]: https://github.com/apple/swift-argument-parser/commits?author=buttaface
[compnerd]: https://github.com/apple/swift-argument-parser/commits?author=compnerd
[dduan]: https://github.com/apple/swift-argument-parser/commits?author=dduan
[elliottwilliams]: https://github.com/apple/swift-argument-parser/commits?author=elliottwilliams
[glessard]: https://github.com/apple/swift-argument-parser/commits?author=glessard
[griffin-stewie]: https://github.com/apple/swift-argument-parser/commits?author=griffin-stewie
[iainsmith]: https://github.com/apple/swift-argument-parser/commits?author=iainsmith
[IngmarStein]: https://github.com/apple/swift-argument-parser/commits?author=IngmarStein
[jonathanpenn]: https://github.com/apple/swift-argument-parser/commits?author=jonathanpenn
[klaaspieter]: https://github.com/apple/swift-argument-parser/commits?author=klaaspieter
[Lantua]: https://github.com/apple/swift-argument-parser/commits?author=Lantua
[miguelangel-dev]: https://github.com/apple/swift-argument-parser/commits?author=miguelangel-dev
[natecook1000]: https://github.com/apple/swift-argument-parser/commits?author=natecook1000
[Sajjon]: https://github.com/apple/swift-argument-parser/commits?author=Sajjon
[sjavora]: https://github.com/apple/swift-argument-parser/commits?author=sjavora
[Wildchild9]: https://github.com/apple/swift-argument-parser/commits?author=Wildchild9
[YuAo]: https://github.com/apple/swift-argument-parser/commits?author=YuAo
[zntfdr]: https://github.com/apple/swift-argument-parser/commits?author=zntfdr

