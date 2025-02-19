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
///   setopt extendedglob nullglob numericglobsort
///   unsetopt aliases banghist
///   ```
public struct CompletionKind {
  internal enum Kind {
    case `default`
    case list([String])
    case file(extensions: [String])
    case directory
    case shellCommand(String)
    case custom(@Sendable ([String]) -> [String])
  }

  internal var kind: Kind

  /// Use the default completion kind for the argument's or option value's type.
  public static var `default`: CompletionKind {
    CompletionKind(kind: .default)
  }

  /// The completion candidates are the strings in the given array.
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

  /// The completion candidates include directory & file names, the latter
  /// filtered by the given list of extensions.
  ///
  /// If the given list of extensions is empty, then file names are not
  /// filtered.
  ///
  /// Given file extensions must not include the `.` initial extension
  /// separator.
  ///
  /// Given file extensions are parsed by the requesting shell as globs; Swift
  /// Argument Parser does not perform any escaping or quoting.
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

  /// The completion candidates are specified by the stdout output of the given
  /// string run as a shell command when a user requests completions.
  ///
  /// Swift Argument Parser does not perform any escaping or quoting on the
  /// given shell command.
  ///
  /// The given shell command is included in a completion script when it is
  /// generated.
  public static func shellCommand(_ command: String) -> CompletionKind {
    CompletionKind(kind: .shellCommand(command))
  }

  /// The completion candidates are the strings in the array returned by the
  /// given closure when it is run when a user requests completions.
  ///
  /// Completion candidates are interpreted by the requesting shell as literals.
  /// They must be neither escaped nor quoted; Swift Argument Parser escapes or
  /// quotes them as necessary for the requesting shell.
  ///
  /// The given closure is evaluated after a user invokes completion in their
  /// shell (normally by pressing TAB); it is not evaluated when a completion
  /// script is generated.
  ///
  /// The array of strings passed to the given closure contains all the shell
  /// words in the command line for the current command at completion
  /// invocation; this is exclusive of words for prior or subsequent commands or
  /// pipes, but inclusive of redirects & any other command line elements. Each
  /// word is its own element in the argument array; they appear in the same
  /// order as in the command line. Note that shell words may contain spaces if
  /// they are escaped or quoted.
  ///
  /// In bash 3-, a process substitution (`<(…)`) in the command line prevents
  /// Swift custom completion functions from being called.
  ///
  /// In bash 4+, a process substitution (`<(…)`) is split into multiple
  /// elements in the argument array: one for the starting `<(`, and one for
  /// each unescaped/unquoted-space-separated token through the closing `)`.
  ///
  /// In bash, if the cursor is between the backslash and the single quote for
  /// the last escaped single quote in a word, all subsequent pipes or other
  /// commands are included in the words passed to Swift. This oddity might
  /// occur only when additional constraints are met. This or similar oddities
  /// might occur in other circumstances.
  ///
  /// In fish 3-, due to a bug, the argument array includes the fish words only
  /// through the word being completed. This is fixed in fish 4+.
  ///
  /// In fish, a redirect's symbol is not included, but its source/target is.
  ///
  /// In zsh, redirects (both their symbol & source/target) are omitted.
  ///
  /// Shell words are passed to Swift verbatim, not unquoted. e.g., the
  /// representation in Swift of the shell word `"abc\\""def"` would be exactly
  /// the same, including the double quotes & the double backslash.
  ///
  /// In fish 3-, due to limitations, words are passed to Swift unquoted. e.g.,
  /// the aforementioned example word would be passed as `abc\def`. This is
  /// fixed in fish 4+.
  @preconcurrency
  public static func custom(
    _ completion: @Sendable @escaping ([String]) -> [String]
  ) -> CompletionKind {
    CompletionKind(kind: .custom(completion))
  }
}

extension CompletionKind: Sendable {}
extension CompletionKind.Kind: Sendable {}
