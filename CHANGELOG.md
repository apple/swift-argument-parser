# CHANGELOG

<!-- 
Add new items at the end of the relevant section under **Unreleased**.
-->

## [Unreleased]

*No changes yet.*

---

## [1.0.1] - 2021-09-14

## Fixes

- Addresses an issue when compiling under Mac Catalyst.

The 1.0.1 release includes a contribution from [imxieyi]. Thank you!

## [1.0.0] - 2021-09-10

The 1.0 release marks an important milestone —
`ArgumentParser` is now source stable!

### Changes

- `ArgumentParser` now provides a DocC documentation catalog, so you
  can view rendered articles and symbol documentation directly within
  Xcode.

### Fixes

- Parsing works as expected for options with single-dash names that
  are declared using the `.upToNextOption` parsing strategy.

---

## [0.5.0] - 2021-09-02

### Additions

- When a user doesn't provide a required argument, the error message now
  includes that argument's help text. ([#324])
- Command-line tools built with `ArgumentParser` now include an experimental
  flag to dump command/argument/help information as JSON:
  `--experimental-dump-help`. ([#310])

### Changes

- All public enumerations are now structs with static properties, to make
  compatibility with future additions simpler.

### Fixes

- Array properties defined as `@Option` with the `.upToNextOption` parsing
  strategy now include all provided values. ([#304]) In the example below, all
  four values are now included in the resulting array, where only the last two
  were included in previous releases:
 
    ```swift   
    struct Example: ParsableCommand {
        @Option(parsing: .upToNextOption)
        var option: [String]
    }
    ```
    ```
    $ example --option one two --option three four
    ```

- When a command defines an array property as an `@Argument` with the
  `.unconditionalRemaining` parsing strategy, option and flag parsing now stops
  at the first positional argument or unrecognized flag. ([#333])
- Completion scripts correctly use customized help flags. ([#308])
- Fixes errors with bash custom completion arguments and the executable path.
  ([#320], [#323])
- Fixes the behavior when a user specifies both the `help` subcommand and a help
  flag. ([#309])
- A variety of internal improvements. ([#315], [#316], [#321], [#341])

The 0.5.0 release includes contributions from [atierian], [compnerd], 
[dirtyhabits97], [Frizlab], [KS1019], [natecook1000], and [rauhul]. Thank you!

---

## [0.4.4] - 2021-07-30

### Fixes

- Includes a workaround for a runtime crash with certain `OptionGroup`
  configurations when a command is compiled in release mode.

## [0.4.3] - 2021-04-28

### Additions

- Experimental API for hiding `@OptionGroup`-declared properties from
  the help screen.

The 0.4.3 release includes a contribution from [miggs597]. Thank you!

## [0.4.2] - 2021-04-21

### Fixes

- Both parts of a flag with an inversion are now hidden when specified.
- Better support for building on OpenBSD.
- Optional unparsed values are now always properly decoded. ([#290])
- Help information from super-commands is no longer unnecessarily injected
  into subcommand help screens. 

The 0.4.2 release includes contributions from [3405691582], [kylemacomber],
[miggs597], [natecook1000], and [werm098]. Thank you!

## [0.4.1] - 2021-03-08

### Additions

- When a user provides an invalid value as an argument or option, the error
  message now includes the help text for that argument.

### Fixes

- Zsh completion scripts for commands that include a hyphen no longer cause
  errors.
- Optional unparsed values are now decoded correctly in `ParsableArguments`
  types.

The 0.4.1 release includes contributions from [adellibovi] and [natecook1000].
Thank you!

## [0.4.0] - 2021-03-04

### Additions

- Short options can now support "joined option" syntax, which lets users specify
  a value appended immediately after the option's short name. For example, in 
  addition to calling this `example` command with `-D debug` and `-D=debug`,
  users can now write `-Ddebug` for the same parsed value. ([#240])

  ```swift
  @main
  struct Example: ParsableCommand {
      @Option(name: .customShort("D", allowingJoined: true))
      var debugValue: String
    
      func run() {
          print(debugValue)
      }
  }
  ```

### Changes

- The `CommandConfiguration.helpNames` property is now optional, to allow the
  overridden help flags of parent commands to flow down to their children. Most
  existing code should not be affected, but if you've customized a command's
  help flags you may see different behavior. ([#251])
- The `errorCode` property is no longer used as a command's exit code when 
  `CustomNSError` types are thrown. ([#276])

  *Migration:* Instead of throwing a `CustomNSError` type, print your error
  manually and throw an `ExitCode` error to customize your command's exit code.

### Removals

- Old, deprecated property wrapper initializers have been removed.

### Fixes

- Validation errors now show the correct help flags when help flags have been 
  customized.
- Options, flags, and arguments that are marked as hidden from the help screen
  are also suppressed from completion scripts.
- Non-parsed variable properties are now allowed in parsable types.
- Error messages produced when `NSError` types are thrown have been improved.
- The usage line for commands with a large number of options includes more 
  detail about required flags and positional arguments.
- Support for CMake builds on Apple Silicon is improved.

The 0.4.0 release includes contributions from [CodaFi], [lorentey],
[natecook1000], [schlagelk], and [Zoha131]. Thank you!

---

## [0.3.2] - 2021-01-15

### Fixes

- Changes made to a command's properties in its `validate` method are now
  persisted.
- The exit code defined by error types that conform to `CustomNSError` are now
  honored.
- Improved error message when declaring a command type with an unadorned 
  mutable property. (See [#256] for more.)
- Migrated from `CRT` to `MSVCRT` for Windows platforms.
- Fixes and improvements for building with CMake for Windows and Apple Silicon.
- Documentation improvements.

The 0.3.2 release includes contributions from [compnerd], [CypherPoet],
[damuellen], [drewmccormack], [elliottwilliams], [gmittert], [MaxDesiatov],
[natecook1000], [pegasuze], and [SergeyPetrachkov]. Thank you!

## [0.3.1] - 2020-09-02

### Fixes

- An option or flag can now declare a name with both single- and double-
  dash prefixes, such as `-my-flag` and `--my-flag`. Specify both names in the
  `name` parameter when declaring your property:
  
  ```swift
  @Flag(name: [.long, .customLong("my-flag", withSingleDash: true)])
  var myFlag = false
  ```

- Parsing performance improvements.

## [0.3.0] - 2020-08-15

### Additions

- Shell completions scripts are now available for Fish.

### Changes

- Array properties without a default value are now treated as required for the
  user of a command-line tool. In previous versions of the library, these
  properties defaulted to an empty array; a deprecation was introduced for this
  behavior in version 0.2.0.

  *Migration:* Specify an empty array as the default value for properties that
  should not require user input:

  ```swift
  // old
  @Option var names: [String]
  // new
  @Option var names: [String] = []
  ```

The 0.3.0 release includes contributions from [dduan], [MPLew-is], 
[natecook1000], and [thomasvl]. Thank you!

---

## [0.2.2] - 2020-08-05

### Fixes

- Zsh completion scripts have improved documentation and better support
  multi-word completion strings, escaped characters, non-standard executable
  locations, and empty help strings.

The 0.2.2 release includes contributions from [interstateone], 
[miguelangel-dev], [natecook1000], [stuartcarnie], and [Wevah]. Thank you!

## [0.2.1] - 2020-07-30

### Additions

- You can now generate Bash and Zsh shell completion scripts for commands, 
  either by using the `--generate-completion-script` flag when running a 
  command, or by calling the static `completionScript(for:)` method on a root 
  `ParsableCommand` type. See the [guide to completion scripts][comp-guide] for 
  information on customizing and installing the completion script for your 
  command.

### Fixes

- Property wrappers without parameters can now be written without parentheses
  — e.g. `@Flag var verbose = false`.
- When displaying default values for array properties, the help screen now 
  correctly uses the element type's `ExpressibleByArgument` conformance to 
  generate the description.
- Running a project that defines a command as its own subcommand now fails with
  a useful error message.

The 0.2.1 release includes contributions from [natecook1000], [NicFontana],
[schlagelk], [sharplet], and [Wevah]. Thank you!

[comp-guide]: https://github.com/apple/swift-argument-parser/blob/main/Documentation/07%20Completion%20Scripts.md

## [0.2.0] - 2020-06-23

### Additions

- You can now specify default values for array properties of parsable types.
  The default values are overridden if the user provides at least one value
  as part of the command-line arguments.

### Changes

- This release of `swift-argument-parser` requires Swift 5.2.
- Default values for all properties are now written using default initialization
  syntax, including some values that were previously implicit, such as empty
  arrays and `false` for Boolean flags.
  
  *Migration:* Specify default values using typical Swift default value syntax
  to remove the deprecation warnings:
  
  ```swift
  // old
  @Flag var verbose: Bool
  // new
  @Flag var verbose = false
  ```
  
  **_Important:_** There is a semantic change for flags with inversions that do
  not have a default value. In previous releases, these flags had a default
  value of `false`; starting in 0.2.0, these flags will have no default, and
  will therefore be required by the user. Specify a default value of `false` to
  retain the old behavior.

### Fixes

- Options with multiple names now consistently show the first-declared name
  in usage and help screens.
- Default subcommands are indicated in the help screen.
- User errors with options are now shown before positional argument errors,
  eliminating some false negative reports.
- CMake compatibility fixes.

The 0.2.0 release includes contributions from [artemnovichkov], [compnerd], 
[ibrahimoktay], [john-mueller], [MPLew-is], [natecook1000], and [owenv]. 
Thank you!

---

## [0.1.0] - 2020-06-03

### Additions

- Error messages and help screens now include information about how to request
  more help.
- CMake builds now support installation.

### Changes

- The `static func main()` method on `ParsableCommand` no longer returns
  `Never`. This allows `ParsableCommand` types to be designated as the entry
  point for a Swift executable by using the `@main` attribute.
  
  *Migration:* For most uses, this change is source compatible. If you have
  used `main()` where a `() -> Never` function is explicitly required, you'll
  need to change your usage or capture the method in another function.

- `Optional` no longer conforms to `ExpressibleByArgument`, to avoid some
  property declarations that don't make sense. 

  *Migration:* This is source-compatible for all property declarations, with
  deprecations for optional properties that define an explicit default. If
  you're using optional values where an `ExpressibleByArgument` type is
  expected, such as a generic function, you will need to change your usage
  or provide an explicit override.

- `ParsableCommand`'s `run()` method requirement is now a `mutating` method,
  allowing mutations to a command's properties, such as sorting an array of
  arguments, without additional copying.
  
  *Migration:* No changes are required for commands that are executed through
  the `main()` method. If you manually parse a command and then call its
  `run()` method, you may need to change the command from a constant to a
  variable.

### Removals

- The `@Flag` initializers that were deprecated in version 0.0.6 are now
  marked as unavailable.

### Fixes

- `@Option` properties of an optional type that use a `transform` closure now
  correctly indicate their optionality in the usage string.
- Correct wrapping and indentation are maintained for abstracts and discussions 
  with short lines.
- Empty abstracts no longer add extra blank lines to the help screen.
- Help requests are still honored even when a parsed command fails validation.
- The `--` terminator isn't consumed when parsing a command, so that it can be
  parsed as a value when a subcommand includes an `.unconditionalRemaining`
  argument array.
- CMake builds work correctly again.

The 0.1.0 release includes contributions from [aleksey-mashanov], [BradLarson],
[compnerd], [erica], [ibrahimoktay], and [natecook1000]. Thank you!

---

## [0.0.6] - 2020-05-14

### Additions

- Command definition validation now checks for name collisions between options
  and flags.
- `ValidationError.message` is now publicly accessible.
- Added an `EnumerableFlag` protocol for `CaseIterable` types that are used to
  provide the names for flags. When declaring conformance to `EnumerableFlag`,
  you can override the name specification and help text for individual flags.
  See [#65] for more detail.
- When a command that requires arguments is called with no arguments at all, 
  the error message includes the full help text instead of the short usage
  string. This is intended to provide a better experience for first-time users.
- Added a `helpMessage()` method for generating the help text for a command
  or subcommand.

### Deprecations

- `@Flag` properties that use `CaseIterable`/`String` types as their values
  are deprecated, and the related `@Flag` initializers will be removed 
  in a future version. 
  
  *Migration:* Add `EnumerableFlag` conformance to the type of these kinds of
  `@Flag` properties.

### Fixes

- Errors thrown while parsing in a `transform` closure are printed correclty
  instead of a general `Invalid state` error.
- Improvements to the guides and in the error message when attempting to access
  a value from an argument/option/flag definition.
- Fixed issues in the CMake and Windows build configurations.
- You can now use an `=` to join a value with an option's short name when calling
  a command. This previously only worked for long names.

The 0.0.6 release includes contributions from [compnerd], [john-mueller], 
[natecook1000], [owenv], [rjstelling], and [toddthomas]. Thank you!

## [0.0.5] - 2020-04-15

### Additions

- You can now specify a version string in a `ParsableCommand`'s configuration.
  The generated tool will then automatically respond to a `--version` flag.
- Command definitions are now validated at runtime in debug mode, to check
  issues that can't be detected during compilation.

### Fixes

- Deprecation warnings during compilation on Linux have been removed.
- The `validate()` method is now called on each command in the matched command
  stack, instead of only the last command in the stack.

The 0.0.5 release includes contributions from [kennyyork], [natecook1000],
[sgl0v], and [YuAo]. Thank you!

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
- `ParsableArguments` types that are declared as `@OptionGroup` properties on
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

---

This changelog's format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

<!-- Link references for releases -->

[Unreleased]: https://github.com/apple/swift-argument-parser/compare/1.0.1...HEAD
[1.0.1]: https://github.com/apple/swift-argument-parser/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/apple/swift-argument-parser/compare/0.5.0...1.0.0
[0.5.0]: https://github.com/apple/swift-argument-parser/compare/0.4.4...0.5.0
[0.4.4]: https://github.com/apple/swift-argument-parser/compare/0.4.3...0.4.4
[0.4.3]: https://github.com/apple/swift-argument-parser/compare/0.4.2...0.4.3
[0.4.2]: https://github.com/apple/swift-argument-parser/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/apple/swift-argument-parser/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/apple/swift-argument-parser/compare/0.3.2...0.4.0
[0.3.2]: https://github.com/apple/swift-argument-parser/compare/0.3.1...0.3.2
[0.3.1]: https://github.com/apple/swift-argument-parser/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/apple/swift-argument-parser/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/apple/swift-argument-parser/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/apple/swift-argument-parser/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/apple/swift-argument-parser/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/apple/swift-argument-parser/compare/0.0.6...0.1.0
[0.0.6]: https://github.com/apple/swift-argument-parser/compare/0.0.5...0.0.6
[0.0.5]: https://github.com/apple/swift-argument-parser/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/apple/swift-argument-parser/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/apple/swift-argument-parser/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/apple/swift-argument-parser/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/apple/swift-argument-parser/releases/tag/0.0.1

<!-- Link references for pull requests -->

[#65]: https://github.com/apple/swift-argument-parser/pull/65
[#240]: https://github.com/apple/swift-argument-parser/pull/240
[#251]: https://github.com/apple/swift-argument-parser/pull/251
[#256]: https://github.com/apple/swift-argument-parser/pull/256
[#276]: https://github.com/apple/swift-argument-parser/pull/276
[#290]: https://github.com/apple/swift-argument-parser/pull/290
[#299]: https://github.com/apple/swift-argument-parser/pull/299
[#304]: https://github.com/apple/swift-argument-parser/pull/304
[#308]: https://github.com/apple/swift-argument-parser/pull/308
[#309]: https://github.com/apple/swift-argument-parser/pull/309
[#310]: https://github.com/apple/swift-argument-parser/pull/310
[#315]: https://github.com/apple/swift-argument-parser/pull/315
[#316]: https://github.com/apple/swift-argument-parser/pull/316
[#320]: https://github.com/apple/swift-argument-parser/pull/320
[#321]: https://github.com/apple/swift-argument-parser/pull/321
[#323]: https://github.com/apple/swift-argument-parser/pull/323
[#324]: https://github.com/apple/swift-argument-parser/pull/324
[#333]: https://github.com/apple/swift-argument-parser/pull/333
[#341]: https://github.com/apple/swift-argument-parser/pull/341

<!-- Link references for contributors -->

[3405691582]: https://github.com/apple/swift-argument-parser/commits?author=3405691582
[adellibovi]: https://github.com/apple/swift-argument-parser/commits?author=adellibovi
[aleksey-mashanov]: https://github.com/apple/swift-argument-parser/commits?author=aleksey-mashanov
[AliSoftware]: https://github.com/apple/swift-argument-parser/commits?author=AliSoftware
[artemnovichkov]: https://github.com/apple/swift-argument-parser/commits?author=artemnovichkov
[atierian]: https://github.com/apple/swift-argument-parser/commits?author=atierian
[BradLarson]: https://github.com/apple/swift-argument-parser/commits?author=BradLarson
[buttaface]: https://github.com/apple/swift-argument-parser/commits?author=buttaface
[CodaFi]: https://github.com/apple/swift-argument-parser/commits?author=CodaFi
[compnerd]: https://github.com/apple/swift-argument-parser/commits?author=compnerd
[CypherPoet]: https://github.com/apple/swift-argument-parser/commits?author=CypherPoet
[damuellen]: https://github.com/apple/swift-argument-parser/commits?author=damuellen
[dduan]: https://github.com/apple/swift-argument-parser/commits?author=dduan
[dirtyhabits97]: https://github.com/apple/swift-argument-parser/commits?author=dirtyhabits97
[drewmccormack]: https://github.com/apple/swift-argument-parser/commits?author=drewmccormack
[elliottwilliams]: https://github.com/apple/swift-argument-parser/commits?author=elliottwilliams
[erica]: https://github.com/apple/swift-argument-parser/commits?author=erica
[Frizlab]: https://github.com/apple/swift-argument-parser/commits?author=Frizlab
[glessard]: https://github.com/apple/swift-argument-parser/commits?author=glessard
[gmittert]: https://github.com/apple/swift-argument-parser/commits?author=gmittert
[griffin-stewie]: https://github.com/apple/swift-argument-parser/commits?author=griffin-stewie
[iainsmith]: https://github.com/apple/swift-argument-parser/commits?author=iainsmith
[ibrahimoktay]: https://github.com/apple/swift-argument-parser/commits?author=ibrahimoktay
[imxieyi]: https://github.com/apple/swift-argument-parser/commits?author=imxieyi
[IngmarStein]: https://github.com/apple/swift-argument-parser/commits?author=IngmarStein
[interstateone]: https://github.com/apple/swift-argument-parser/commits?author=interstateone
[john-mueller]: https://github.com/apple/swift-argument-parser/commits?author=john-mueller
[jonathanpenn]: https://github.com/apple/swift-argument-parser/commits?author=jonathanpenn
[kennyyork]: https://github.com/apple/swift-argument-parser/commits?author=kennyyork
[klaaspieter]: https://github.com/apple/swift-argument-parser/commits?author=klaaspieter
[KS1019]: https://github.com/apple/swift-argument-parser/commits?author=KS1019
[kylemacomber]: https://github.com/apple/swift-argument-parser/commits?author=kylemacomber
[Lantua]: https://github.com/apple/swift-argument-parser/commits?author=Lantua
[lorentey]: https://github.com/apple/swift-argument-parser/commits?author=lorentey
[MaxDesiatov]: https://github.com/apple/swift-argument-parser/commits?author=MaxDesiatov
[miggs597]: https://github.com/apple/swift-argument-parser/commits?author=miggs597
[miguelangel-dev]: https://github.com/apple/swift-argument-parser/commits?author=miguelangel-dev
[MPLew-is]: https://github.com/apple/swift-argument-parser/commits?author=MPLew-is
[natecook1000]: https://github.com/apple/swift-argument-parser/commits?author=natecook1000
[NicFontana]: https://github.com/apple/swift-argument-parser/commits?author=NicFontana
[owenv]: https://github.com/apple/swift-argument-parser/commits?author=owenv
[pegasuze]: https://github.com/apple/swift-argument-parser/commits?author=pegasuze
[rauhul]: https://github.com/apple/swift-argument-parser/commits?author=rauhul
[rjstelling]: https://github.com/apple/swift-argument-parser/commits?author=rjstelling
[Sajjon]: https://github.com/apple/swift-argument-parser/commits?author=Sajjon
[schlagelk]: https://github.com/apple/swift-argument-parser/commits?author=schlagelk
[SergeyPetrachkov]: https://github.com/apple/swift-argument-parser/commits?author=SergeyPetrachkov
[sgl0v]: https://github.com/apple/swift-argument-parser/commits?author=sgl0v
[sharplet]: https://github.com/apple/swift-argument-parser/commits?author=sharplet
[sjavora]: https://github.com/apple/swift-argument-parser/commits?author=sjavora
[stuartcarnie]: https://github.com/apple/swift-argument-parser/commits?author=stuartcarnie
[thomasvl]: https://github.com/apple/swift-argument-parser/commits?author=thomasvl
[toddthomas]: https://github.com/apple/swift-argument-parser/commits?author=toddthomas
[werm098]: https://github.com/apple/swift-argument-parser/commits?author=werm098
[Wevah]: https://github.com/apple/swift-argument-parser/commits?author=Wevah
[Wildchild9]: https://github.com/apple/swift-argument-parser/commits?author=Wildchild9
[YuAo]: https://github.com/apple/swift-argument-parser/commits?author=YuAo
[zntfdr]: https://github.com/apple/swift-argument-parser/commits?author=zntfdr
[Zoha131]: https://github.com/apple/swift-argument-parser/commits?author=Zoha131
