//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !os(Windows) && !os(WASI) && canImport(Darwin)

import Foundation
import XCTest

// MARK: - Shell Availability

/// Checks whether a shell is available on the system.
public func isShellAvailable(_ shell: String) -> Bool {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [shell, "--version"]
  process.standardOutput = FileHandle.nullDevice
  process.standardError = FileHandle.nullDevice
  do {
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus == 0
  } catch {
    return false
  }
}

// MARK: - Bash Completion Harness

/// Invokes a bash completion function programmatically by setting COMP_LINE,
/// COMP_WORDS, COMP_CWORD, and COMP_POINT, then prints COMPREPLY.
///
/// - Parameters:
///   - commandLine: The simulated command line text (e.g., "math stats ").
///     A trailing space means we're completing a new word after the last token.
///   - completionScript: The full text of the bash completion script.
///   - binaryDir: The directory containing the command binary, added to PATH.
/// - Returns: An array of completion results.
/// - Throws: `ShellCompletionError` if the shell script fails.
public func bashCompletions(
  commandLine: String,
  completionScript: String,
  binaryDir: String
) throws -> [String] {
  // Parse the command line into words the way bash would.
  // A trailing space means there's an empty word being completed.
  let trailingSpace = commandLine.hasSuffix(" ")
  let words =
    commandLine
    .split(separator: " ", omittingEmptySubsequences: true)
    .map(String.init)

  // COMP_CWORD is the index of the word being completed.
  // If there's a trailing space, we're completing a new (empty) word.
  let compCword: Int
  let compWords: [String]
  if trailingSpace {
    compCword = words.count
    compWords = words + [""]
  } else {
    compCword = words.count - 1
    compWords = words
  }

  let compLine = commandLine
  let compPoint = commandLine.utf8.count

  // The completion function name is derived from the command name.
  // The generated scripts register via: complete -o filenames -F _<name> <name>
  // We extract the function name from the script to be safe.
  let completionFunc =
    extractBashCompletionFunction(from: completionScript)
    ?? "_\(words[0])"

  let cur = compWords[compCword]
  let prev = compCword > 0 ? compWords[compCword - 1] : ""

  // Build COMP_WORDS as a bash array literal
  let compWordsLiteral =
    compWords
    .map { bashQuote($0) }
    .joined(separator: " ")

  // Write the completion script to a temp file to avoid escaping issues.
  // The generated scripts contain $'\n' and other constructs that are
  // impossible to safely embed inside single-quoted eval strings.
  let tempDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("sap-completion-test-\(UUID().uuidString)")
  try FileManager.default.createDirectory(
    at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let completionScriptFile = tempDir.appendingPathComponent("completions.bash")
  try completionScript.write(
    to: completionScriptFile, atomically: true, encoding: .utf8)

  let testScript = """
    #!/bin/bash
    export PATH=\(bashQuote(binaryDir)):$PATH

    # Source the completion script from a temp file
    source \(bashQuote(completionScriptFile.path))

    # Set up completion variables
    COMP_LINE=\(bashQuote(compLine))
    COMP_WORDS=(\(compWordsLiteral))
    COMP_CWORD=\(compCword)
    COMP_POINT=\(compPoint)
    COMPREPLY=()

    # Call the completion function: func $1(command) $2(current_word) $3(previous_word)
    \(completionFunc) \(bashQuote(compWords[0])) \(bashQuote(cur)) \(bashQuote(prev))

    # Output results, one per line (only if non-empty)
    if [[ ${#COMPREPLY[@]} -gt 0 ]]; then
        printf '%s\\n' "${COMPREPLY[@]}"
    fi
    """

  return try runShellScript(shell: "/bin/bash", script: testScript)
}

/// Extracts the completion function name from a bash completion script
/// by finding the `complete -F <func>` line.
private func extractBashCompletionFunction(from script: String) -> String? {
  for line in script.split(separator: "\n") {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix("complete ") else { continue }
    let parts = trimmed.split(separator: " ")
    if let fIndex = parts.firstIndex(of: "-F"),
      fIndex + 1 < parts.endIndex
    {
      return String(parts[fIndex + 1])
    }
  }
  return nil
}

/// Safely quotes a string for bash using single quotes.
private func bashQuote(_ s: String) -> String {
  "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

// MARK: - Fish Completion Harness

/// Uses fish's `complete -C` to query completions programmatically.
///
/// - Parameters:
///   - commandLine: The simulated command line text (e.g., "math stats ").
///   - completionScript: The full text of the fish completion script.
///   - binaryDir: The directory containing the command binary, added to PATH.
/// - Returns: An array of completion results (descriptions stripped).
/// - Throws: `ShellCompletionError` if the shell script fails.
public func fishCompletions(
  commandLine: String,
  completionScript: String,
  binaryDir: String
) throws -> [String] {
  let fishPath = findShell("fish")
  guard let fishPath else {
    throw ShellCompletionError.shellNotAvailable("fish")
  }

  // Write the completion script to a temp file
  let tempDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("sap-completion-test-\(UUID().uuidString)")
  try FileManager.default.createDirectory(
    at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let completionScriptFile = tempDir.appendingPathComponent("completions.fish")
  try completionScript.write(
    to: completionScriptFile, atomically: true, encoding: .utf8)

  // Fish's `complete -C` returns "completion\tdescription" pairs, one per line.
  let testScript = """
    set -x PATH \(fishQuote(binaryDir)) $PATH

    # Source the completion script from a temp file
    source \(fishQuote(completionScriptFile.path))

    # Query completions
    complete -C \(fishQuote(commandLine))
    """

  let results = try runShellScript(shell: fishPath, script: testScript)

  // Fish outputs "completion\tdescription" — strip the description part
  return results.map { line in
    if let tabIndex = line.firstIndex(of: "\t") {
      return String(line[..<tabIndex])
    }
    return line
  }
}

/// Safely quotes a string for fish using single quotes.
private func fishQuote(_ s: String) -> String {
  "'"
    + s.replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: "'", with: "\\'") + "'"
}

// MARK: - Zsh Completion Harness

/// Uses zsh's `zsh/zpty` pseudo-TTY module to test completions in a real
/// interactive zsh session.
///
/// This is necessary because zsh's completion system
/// (`_arguments`, `_describe`, `compadd`) requires the full ZLE (Zsh Line
/// Editor) context that only exists during actual completion in an interactive
/// shell.
///
/// The approach:
/// 1. A driver script starts an interactive zsh in a pseudo-terminal via `zpty`
/// 2. Sources a setup script that initializes `compinit`, sources the completion
///    script, and defines a `zle-line-init` widget that auto-triggers on the
///    next prompt
/// 3. The widget sets `BUFFER` to the command line, runs `_main_complete` with
///    a `compadd` override to capture completions, writes them to a temp file,
///    then exits the shell
/// 4. The driver waits for the results file to appear, then outputs its contents
///
/// - Parameters:
///   - commandLine: The simulated command line text (e.g., "math stats ").
///   - completionScript: The full text of the zsh completion script.
///   - binaryDir: The directory containing the command binary, added to PATH.
/// - Returns: An array of completion results.
/// - Throws: `ShellCompletionError` if the shell script fails.
public func zshCompletions(
  commandLine: String,
  completionScript: String,
  binaryDir: String
) throws -> [String] {
  let zshPath = findShell("zsh")
  guard let zshPath else {
    throw ShellCompletionError.shellNotAvailable("zsh")
  }

  // Write all scripts to a temp directory
  let tempDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("sap-completion-test-\(UUID().uuidString)")
  try FileManager.default.createDirectory(
    at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let completionScriptFile = tempDir.appendingPathComponent("completions.zsh")
  try completionScript.write(
    to: completionScriptFile, atomically: true, encoding: .utf8)

  // The results file where the widget writes completions.
  let resultsFile = tempDir.appendingPathComponent("results.txt")
  // A sentinel file that signals the widget has finished writing.
  let doneFile = tempDir.appendingPathComponent("done")

  // Write the setup script that will be sourced inside the interactive pty.
  let setupScript = zshSetupScript(
    completionScriptPath: completionScriptFile.path,
    binaryDir: binaryDir,
    commandLine: commandLine,
    resultsPath: resultsFile.path,
    donePath: doneFile.path
  )
  let setupScriptFile = tempDir.appendingPathComponent("setup.zsh")
  try setupScript.write(
    to: setupScriptFile, atomically: true, encoding: .utf8)

  // Write the driver script that manages the zpty session.
  let driverScript = zshDriverScript(
    setupScriptPath: setupScriptFile.path,
    donePath: doneFile.path,
    resultsPath: resultsFile.path
  )
  let driverScriptFile = tempDir.appendingPathComponent("driver.zsh")
  try driverScript.write(
    to: driverScriptFile, atomically: true, encoding: .utf8)

  let process = Process()
  process.executableURL = URL(fileURLWithPath: zshPath)
  process.arguments = [driverScriptFile.path]

  // Prevent loading user's zsh config
  process.environment = [
    "ZDOTDIR": "/nonexistent",
    "PATH":
      "\(binaryDir):\(ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin")",
    "HOME": ProcessInfo.processInfo.environment["HOME"] ?? "/tmp",
    "TERM": "xterm",
  ]

  let stdoutPipe = Pipe()
  let stderrPipe = Pipe()
  process.standardOutput = stdoutPipe
  process.standardError = stderrPipe

  try process.run()

  // Read pipes on background threads to avoid deadlock
  let stdoutBox = SendableBox()
  let stderrBox = SendableBox()
  let group = DispatchGroup()

  group.enter()
  DispatchQueue.global().async {
    stdoutBox.data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    group.leave()
  }
  group.enter()
  DispatchQueue.global().async {
    stderrBox.data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    group.leave()
  }

  // Kill the process if it takes longer than 30 seconds
  let killWork = DispatchWorkItem { process.terminate() }
  DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: killWork)

  process.waitUntilExit()
  killWork.cancel()
  group.wait()

  let stdout = String(data: stdoutBox.data, encoding: .utf8) ?? ""

  if process.terminationStatus != 0 {
    let stderr = String(data: stderrBox.data, encoding: .utf8) ?? ""
    throw ShellCompletionError.executionFailed(
      status: process.terminationStatus,
      stderr: "zsh driver failed: \(stderr)\nstdout: \(stdout)")
  }

  // The driver script outputs the results file contents on stdout
  return
    stdout
    .split(separator: "\n", omittingEmptySubsequences: true)
    .map(String.init)
}

/// Builds the zsh setup script that is sourced inside the interactive pty.
///
/// This script:
/// 1. Initializes the completion system via `compinit`
/// 2. Sources the generated completion script
/// 3. Registers a completion capture widget (`zle -C`) that overrides `compadd`
///    to intercept completion results and write them to a file
/// 4. Registers a `zle-line-init` hook that auto-fires on the next prompt,
///    sets BUFFER/CURSOR, and invokes the capture widget
private func zshSetupScript(
  completionScriptPath: String,
  binaryDir: String,
  commandLine: String,
  resultsPath: String,
  donePath: String
) -> String {
  """
  PS1=""

  export PATH='\(binaryDir.replacingOccurrences(of: "'", with: "'\\''"))':"$PATH"

  autoload -Uz compinit && compinit -u &>/dev/null

  source '\(completionScriptPath.replacingOccurrences(of: "'", with: "'\\''"))'

  # Completion capture function — registered as a COMPLETION widget via
  # "zle -C" so that it runs inside the completion system's context.
  # This is required because _main_complete, compstate, compadd etc.
  # only work when called from within a completion widget (not a regular
  # widget registered with "zle -N").
  __sap_capture() {
      local -a _results=()

      compadd() {
          # Use the real compadd builtin with -O to capture the completions
          # it would have added. This lets zsh handle all option parsing,
          # prefix filtering, and match specs natively — we just collect
          # the results.
          local -a _capture=()
          builtin compadd -O _capture "$@"
          (( ${#_capture} )) && _results+=("${_capture[@]}")
      }

      _main_complete

      unfunction compadd 2>/dev/null

      # Deduplicate: the completion system may call compadd multiple
      # times for the same items (e.g. _describe calls it internally).
      local -aU _unique_results=("${_results[@]}")
      (( ${#_unique_results} )) && printf "%s\\n" "${_unique_results[@]}" > \(zshQuote(resultsPath))
      touch \(zshQuote(donePath))
  }
  zle -C __sap_capture complete-word __sap_capture

  # Auto-trigger: zle-line-init fires on the next prompt. It sets BUFFER
  # and CURSOR, then invokes the completion widget (which runs in the
  # proper completion context).
  __sap_auto_trigger() {
      zle -D zle-line-init 2>/dev/null

      BUFFER=\(zshQuote(commandLine))
      CURSOR=$#BUFFER

      zle __sap_capture

      BUFFER="exit 0"
      zle accept-line
  }
  zle -N zle-line-init __sap_auto_trigger
  """
}

/// Builds the zsh driver script that manages the zpty session.
///
/// The driver sources the setup script, then polls for the done sentinel
/// file. Once it appears, it reads and outputs the results file.
private func zshDriverScript(
  setupScriptPath: String,
  donePath: String,
  resultsPath: String
) -> String {
  """
  #!/bin/zsh
  setopt no_monitor
  zmodload zsh/zpty || exit 1

  ZDOTDIR=/nonexistent zpty _comp zsh -f -i 2>/dev/null

  zpty -w _comp 'source \(zshQuote(setupScriptPath))'

  # Poll for done file while draining pty output. MUST drain or child blocks
  # on write when the pty output buffer fills up.
  local -i _tries=300
  while (( _tries-- )); do
      if zpty -t _comp 2>/dev/null; then
          local _discard=""
          zpty -r _comp _discard 2>/dev/null
      fi
      [[ -f \(zshQuote(donePath)) ]] && break
      sleep 0.05
  done

  zpty -d _comp 2>/dev/null

  if [[ -f \(zshQuote(resultsPath)) ]]; then
      cat \(zshQuote(resultsPath))
  fi
  """
}

/// Safely quotes a string for zsh using single quotes.
private func zshQuote(_ s: String) -> String {
  "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

// MARK: - Helpers

/// Thread-safe box for accumulating Data across Sendable boundaries.
private final class SendableBox: @unchecked Sendable {
  var data = Data()
}

public enum ShellCompletionError: Error, CustomStringConvertible {
  case shellNotAvailable(String)
  case executionFailed(status: Int32, stderr: String)

  public var description: String {
    switch self {
    case .shellNotAvailable(let shell):
      return "Shell '\(shell)' is not available on this system"
    case .executionFailed(let status, let stderr):
      return "Shell script failed with status \(status): \(stderr)"
    }
  }
}

/// Finds the path to a shell binary.
private func findShell(_ name: String) -> String? {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["which", name]
  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = FileHandle.nullDevice
  do {
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
  } catch {
    return nil
  }
}

/// Runs a shell script and returns the stdout lines.
private func runShellScript(shell: String, script: String) throws -> [String] {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: shell)
  process.arguments = []

  let stdinPipe = Pipe()
  let stdoutPipe = Pipe()
  let stderrPipe = Pipe()

  process.standardInput = stdinPipe
  process.standardOutput = stdoutPipe
  process.standardError = stderrPipe

  try process.run()

  // Write the script to stdin and close
  stdinPipe.fileHandleForWriting.write(script.data(using: .utf8)!)
  stdinPipe.fileHandleForWriting.closeFile()

  process.waitUntilExit()

  let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
  let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
  let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
  let stderr = String(data: stderrData, encoding: .utf8) ?? ""

  guard process.terminationStatus == 0 else {
    throw ShellCompletionError.executionFailed(
      status: process.terminationStatus, stderr: stderr)
  }

  return
    stdout
    .split(separator: "\n", omittingEmptySubsequences: true)
    .map(String.init)
}

// MARK: - XCTest Assertions

extension XCTest {
  /// Asserts that bash completions for a given command line match expected values.
  ///
  /// - Parameters:
  ///   - commandLine: The command line to complete (e.g., "math stats ").
  ///   - expected: The expected completion values (order-independent).
  ///   - binaryDir: Directory containing the command binary.
  ///   - completionScript: The bash completion script text.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  public func AssertBashCompletions(
    _ commandLine: String,
    expected: [String],
    binaryDir: String,
    completionScript: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let results = try bashCompletions(
      commandLine: commandLine,
      completionScript: completionScript,
      binaryDir: binaryDir
    )
    XCTAssertEqual(
      results.sorted(), expected.sorted(),
      "Bash completions for '\(commandLine)'",
      file: file, line: line
    )
  }

  /// Asserts that fish completions for a given command line match expected values.
  ///
  /// - Parameters:
  ///   - commandLine: The command line to complete (e.g., "math stats ").
  ///   - expected: The expected completion values (order-independent).
  ///   - binaryDir: Directory containing the command binary.
  ///   - completionScript: The fish completion script text.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  public func AssertFishCompletions(
    _ commandLine: String,
    expected: [String],
    binaryDir: String,
    completionScript: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let results = try fishCompletions(
      commandLine: commandLine,
      completionScript: completionScript,
      binaryDir: binaryDir
    )
    XCTAssertEqual(
      results.sorted(), expected.sorted(),
      "Fish completions for '\(commandLine)'",
      file: file, line: line
    )
  }

  /// Asserts that zsh completions for a given command line match expected values.
  ///
  /// - Parameters:
  ///   - commandLine: The command line to complete (e.g., "math stats ").
  ///   - expected: The expected completion values (order-independent).
  ///   - binaryDir: Directory containing the command binary.
  ///   - completionScript: The zsh completion script text.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  public func AssertZshCompletions(
    _ commandLine: String,
    expected: [String],
    binaryDir: String,
    completionScript: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let results = try zshCompletions(
      commandLine: commandLine,
      completionScript: completionScript,
      binaryDir: binaryDir
    )
    XCTAssertEqual(
      results.sorted(), expected.sorted(),
      "Zsh completions for '\(commandLine)'",
      file: file, line: line
    )
  }
}

#endif
