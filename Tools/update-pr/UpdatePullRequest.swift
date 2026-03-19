//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation

@main
struct UpdatePullRequest: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-pr",
    abstract:
      "Update a PR branch with latest from main, maintaining authorship."
  )

  @Argument(help: "URL of the remote to add.")
  var remoteURL: String

  @Argument(help: "Branch name on that remote to check out.")
  var remoteBranch: String

  @Option(help: "Name to give the remote.")
  var remoteName: String = "upstream"

  mutating func run() throws {
    try requireInsideGitRepository()
    try requireCleanWorktree()

    print("Switching to main...")
    try git("switch", "main")

    print("Pulling latest changes for main...")
    try git("pull", "--ff-only", "origin", "main")

    try addRemoteIfNeeded(name: remoteName, url: remoteURL)

    print("Fetching remote '\(remoteName)'...")
    try git("fetch", remoteName)

    try ensureRemoteBranchExists(remoteName: remoteName, branch: remoteBranch)

    let localBranch = remoteBranch
    try ensureLocalBranchDoesNotExist(localBranch)

    print(
      "Checking out branch '\(localBranch)' from '\(remoteName)/\(remoteBranch)'..."
    )
    try git(
      "switch", "-c", localBranch, "--track", "\(remoteName)/\(remoteBranch)")

    print("Finding author of the last commit on '\(localBranch)'...")
    let authorName = try git("log", "-1", "--format=%an")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let authorEmail = try git("log", "-1", "--format=%ae")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    print("Last commit author: \(authorName) <\(authorEmail)>")

    print("Merging latest main into '\(localBranch)'...")
    try git("merge", "--no-ff", "main")

    print("Rewriting merge commit author to match previous commit author...")
    try git(
      "commit",
      "--amend",
      "--author",
      "\(authorName) <\(authorEmail)>",
      "--no-edit"
    )

    print("Done.")
    print("")
    let currentBranch = try git("branch", "--show-current")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    print("Current branch: \(currentBranch)")

    let finalAuthor = try git("log", "-1", "--format=%an <%ae>")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    print("Merge commit author is now:")
    print("  \(finalAuthor)")

    if !checkCleanWorktree() {
      print("Formatting changes detected, committing...")
      try git("add", ".")
      try git(
        "commit",
        "-m",
        "Update formatting",
        "--author",
        "\(authorName) <\(authorEmail)>"
      )
      print("Done.")
    }
  }
}

// MARK: - Git helpers

extension UpdatePullRequest {
  func requireInsideGitRepository() throws {
    do {
      _ = try git("rev-parse", "--is-inside-work-tree")
    } catch {
      throw RuntimeError("Not inside a Git repository.")
    }
  }

  func checkCleanWorktree() -> Bool {
    switch try? requireCleanWorktree() {
    case nil: return false
    case _: return true
    }
  }

  func requireCleanWorktree() throws {
    guard let unstaged = try? git("diff", "--quiet", allowFailure: true),
      unstaged.isEmpty
    else {
      throw RuntimeError("Working tree has unstaged changes; aborting.")
    }

    guard
      let staged = try? git("diff", "--cached", "--quiet", allowFailure: true),
      staged.isEmpty
    else {
      throw RuntimeError(
        "Index has staged but uncommitted changes; aborting.")
    }

    let untracked = try git("ls-files", "--others", "--exclude-standard")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !untracked.isEmpty {
      throw RuntimeError("Repository has untracked files; aborting.")
    }
  }

  func addRemoteIfNeeded(name: String, url: String) throws {
    do {
      let existingURL = try git("remote", "get-url", name)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if existingURL != url {
        throw ValidationError(
          "Remote '\(name)' already exists with different URL: \(existingURL)")
      }
      print("Remote '\(name)' already exists with matching URL")
    } catch {
      try git("remote", "add", name, url)
      print("Added remote '\(name)' -> \(url)")
    }
  }

  func ensureRemoteBranchExists(remoteName: String, branch: String) throws {
    do {
      try git(
        "show-ref", "--verify", "--quiet",
        "refs/remotes/\(remoteName)/\(branch)")
    } catch {
      throw ValidationError(
        "Remote branch '\(remoteName)/\(branch)' does not exist.")
    }
  }

  func ensureLocalBranchDoesNotExist(_ name: String) throws {
    do {
      try git("show-ref", "--verify", "--quiet", "refs/heads/\(name)")
    } catch {
      // Failure means we didn't find a branch :thumbs-up:
      return
    }
    throw ValidationError(
      "Local branch '\(name)' already exists; refusing to overwrite it.")
  }

  @discardableResult
  func git(
    _ args: String...,
    allowFailure: Bool = false,
    requireSuccess: Bool = true
  ) throws -> String {
    let result = ProcessRunner.run(
      "/usr/bin/env",
      arguments: ["git"] + args
    )

    if requireSuccess && result.exitCode != 0 {
      let message =
        result.stderr.isEmpty
        ? "git \(args.joined(separator: " ")) failed"
        : result.stderr
      throw RuntimeError(
        message.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    if !allowFailure && !requireSuccess && result.exitCode != 0 {
      let message =
        result.stderr.isEmpty
        ? "git \(args.joined(separator: " ")) failed"
        : result.stderr
      throw RuntimeError(
        message.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    return result.stdout
  }
}

// MARK: - Process runner

struct ProcessRunner {
  struct Result {
    let exitCode: Int32
    let stdout: String
    let stderr: String
  }

  static func run(
    _ executable: String,
    arguments: [String],
  ) -> Result {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    return Result(
      exitCode: process.terminationStatus,
      stdout: String(data: stdoutData, encoding: .utf8) ?? "",
      stderr: String(data: stderrData, encoding: .utf8) ?? ""
    )
  }
}

// MARK: - Errors

struct RuntimeError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}
