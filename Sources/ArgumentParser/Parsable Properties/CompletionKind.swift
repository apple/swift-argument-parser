//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The type of completion to use for an argument or option value.
///
/// For all `CompletionKind`s, the completion shell script is configured with
/// the following settings, which will not affect the requesting shell outside
/// the completion script:
///
/// - bash:
///
///   ```shell
///   shopt -s extglob
///   set +o history +o posix
///   ```
///
/// - fish: no settings
///
/// - zsh:
///
///   ```shell
///   emulate -RL zsh -G
///   setopt extendedglob
///   unsetopt aliases banghist
///   ```
public struct CompletionKind {
  /// The type of completion to use for an argument or option value.
  ///
  /// For all `Kind`s, the completion shell script is configured with the
  /// following settings, which will not affect the requesting shell outside the
  /// completion script:
  ///
  /// - bash:
  ///
  ///   ```shell
  ///   shopt -s extglob
  ///   set +o history +o posix
  ///   ```
  ///
  /// - fish: no settings
  ///
  /// - zsh:
  ///
  ///   ```shell
  ///   emulate -RL zsh -G
  ///   setopt extendedglob
  ///   unsetopt aliases banghist
  ///   ```
  internal enum Kind {
    /// Use the default completion kind for the argument's or option value's
    /// type.
    case `default`

    /// The completion candidates are the elements of the given `[String]`.
    ///
    /// Completion candidates are interpreted by the requesting shell as
    /// literals. They must be neither escaped nor quoted; Swift Argument Parser
    /// escapes or quotes them as necessary for the requesting shell.
    ///
    /// The completion candidates are included in a completion script when it is
    /// generated.
    case list([String])

    /// The completion candidates include:
    ///
    /// - all directory names
    /// - if `extensions` is empty, all file names
    /// - if `extensions` is not empty, all file names whose respective
    ///   extension matches any element of `extensions`
    ///
    /// Given file extensions must not include the `.` initial extension
    /// separator.
    ///
    /// Given file extensions are parsed by the requesting shell as globs; Swift
    /// Argument Parser does not perform any escaping or quoting.
    ///
    /// In zsh, `EXTENDED_GLOB` & `NULL_GLOB` are set, while `KSH_GLOB` & `SH_GLOB` are unset
    /// ? `BARE_GLOB_QUAL`, `GLOB_DOTS`, `GLOB_STAR_SHORT`, `GLOB_SUBST`, `NOMATCH`, `NUMERIC_GLOB_SORT`
    ///
    /// The directory/file filter & the given list of extensions are included in
    /// a completion script when it is generated.
    case file(extensions: [String])

    /// The completion candidates are directory names.
    ///
    /// The directory filter is included in a completion script when it is
    /// generated.
    case directory

    /// The completion candidates are specified by the stdout output of the
    /// given `String` run as a shell command when a user requests completions.
    ///
    /// Swift Argument Parser does not perform any escaping or quoting on the
    /// given shell command.
    ///
    /// The given shell command is included in a completion script when it is
    /// generated.
    case shellCommand(String)

    /// The completion candidates are the elements of the `[String]` returned by
    /// the given closure when it is run when a user requests completions.
    ///
    /// Completion candidates are interpreted by the requesting shell as
    /// literals. They must be neither escaped nor quoted; Swift Argument Parser
    /// escapes or quotes them as necessary for the requesting shell.
    ///
    /// The given closure is evaluated after a user invokes completion in their
    /// shell (normally by pressing TAB); it is not evaluated when a completion
    /// script is generated.
    ///
    /// Depending on which shell is requesting completions, the `[String]`
    /// argument passed to the given closure contains:
    ///
    /// - the command being called as the first element (bash & fish, not zsh)
    /// - either:
    ///   - all the arguments on the command line (bash & zsh, presumably fish
    ///     4+)
    ///   - the arguments on the command line only up to & including the
    ///     argument for which completions are being requested (fish 3-)
    ///
    /// The arguments are passed to Swift verbatim, not unquoted. e.g., the
    /// representation in Swift of the shell argument `"abc\\""def"` would be
    /// exactly the same, including the quotes & the double backslash.
    ///
    /// Due to limitations in fish 3, arguments are passed to Swift unquoted.
    /// e.g., the aforementioned example argument would be passed as `abc\def`.
    /// fish 4 will not be constrained by such limitations, so this behavior
    /// will be able to be fixed in a subsequent update to Swift Argument
    /// Parser.
    case custom(@Sendable ([String]) -> [String])
  }

  internal var kind: Kind

  /// Use the default completion kind for the argument's or option value's type.
  public static var `default`: CompletionKind {
    CompletionKind(kind: .default)
  }

  /// The completion candidates are the elements of `words`.
  ///
  /// Completion candidates are interpreted by the requesting shell as literals.
  /// They must be neither escaped nor quoted; Swift Argument Parser escapes or
  /// quotes them as necessary for the requesting shell.
  ///
  /// The completion candidates are included in a completion script when it is
  /// generated.
  public static func list(_ words: [String]) -> CompletionKind {
    CompletionKind(kind: .list(words))
  }

  // swift-format-ignore: BeginDocumentationCommentWithOneLineSummary
  /// The completion candidates include:
  ///
  /// - all directory names
  /// - if `extensions` is empty, all file names
  /// - if `extensions` is not empty, all file names whose respective
  ///   extension matches any element of `extensions`
  ///
  /// Given file extensions must not include the `.` initial extension
  /// separator.
  ///
  /// Given file extensions are parsed by the requesting shell as globs; Swift
  /// Argument Parser does not perform any escaping or quoting.
  ///
  /// In zsh, `EXTENDED_GLOB` & `NULL_GLOB` are set, while `KSH_GLOB` & `SH_GLOB` are unset
  /// ? `BARE_GLOB_QUAL`, `GLOB_DOTS`, `GLOB_STAR_SHORT`, `GLOB_SUBST`, `NOMATCH`, `NUMERIC_GLOB_SORT`
  ///
  /// The directory/file filter & the given list of extensions are included in a
  /// completion script when it is generated.
  public static func file(extensions: [String] = []) -> CompletionKind {
    CompletionKind(kind: .file(extensions: extensions))
  }

  /// The completion candidates are directory names.
  ///
  /// The directory filter is included in a completion script when it is
  /// generated.
  public static var directory: CompletionKind {
    CompletionKind(kind: .directory)
  }

  /// The completion candidates are specified by the stdout output of `command`
  /// run as a shell command when a user requests completions.
  ///
  /// Swift Argument Parser does not perform any escaping or quoting on
  /// `command`.
  ///
  /// The given shell command is included in a completion script when it is
  /// generated.
  public static func shellCommand(_ command: String) -> CompletionKind {
    CompletionKind(kind: .shellCommand(command))
  }

  /// The completion candidates are the elements of the `[String]` returned by
  /// the given closure when it is run when a user requests completions.
  ///
  /// Completion candidates are interpreted by the requesting shell as literals.
  /// They must be neither escaped nor quoted; Swift Argument Parser escapes or
  /// quotes them as necessary for the requesting shell.
  ///
  /// The given closure is evaluated after a user invokes completion in their
  /// shell (normally by pressing TAB); it is not evaluated when a completion
  /// script is generated.
  ///
  /// Depending on which shell is requesting completions, the `[String]`
  /// argument passed to the given closure contains:
  ///
  /// - the command being called as the first element (bash & fish, not zsh)
  /// - either:
  ///   - all the arguments on the command line (bash & zsh, presumably fish 4+)
  ///   - the arguments on the command line only up to & including the argument
  ///     for which completions are being requested (fish 3-)
  ///
  /// The arguments are passed to Swift verbatim, not unquoted. e.g., the
  /// representation in Swift of the shell argument `"abc\\""def"` would be
  /// exactly the same, including the quotes & the double backslash.
  ///
  /// Due to limitations in fish 3, arguments are passed to Swift unquoted.
  /// e.g., the aforementioned example argument would be passed as `abc\def`.
  /// fish 4 will not be constrained by such limitations, so this behavior will
  /// be able to be fixed in a subsequent update to Swift Argument Parser.
  @preconcurrency
  public static func custom(
    _ completion: @Sendable @escaping ([String]) -> [String]
  ) -> CompletionKind {
    CompletionKind(kind: .custom(completion))
  }
}

extension CompletionKind: Sendable {}
extension CompletionKind.Kind: Sendable {}
