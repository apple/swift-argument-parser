//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Help information for a command-line argument.
public struct ArgumentHelp {
  /// A short description of the argument.
  public var abstract: String = ""
  
  /// An expanded description of the argument, in plain text form.
  public var discussion: String = ""

  /// Additional detailed description of the argument, in plain text form.
  ///
  /// This discussion is shown in the detailed help display and supplemental
  /// content such as generated manuals.
  public var detailedDiscussion: String = ""

  /// An alternative name to use for the argument's value when showing usage
  /// information.
  ///
  /// - Note: This property is ignored when generating help for flags, since
  ///   flags don't include a value.
  public var valueName: String?
  
  /// A visibility level indicating whether this argument should be shown in
  /// the extended help display.
  public var visibility: ArgumentVisibility = .default

  /// Creates a new help instance.
  public init(
    _ abstract: String = "",
    discussion: String = "",
    detailedDiscussion: String = "",
    valueName: String? = nil,
    visibility: ArgumentVisibility = .default)
  {
    self.abstract = abstract
    self.discussion = discussion
    self.detailedDiscussion = detailedDiscussion
    self.valueName = valueName
    self.visibility = visibility
  }

  /// A `Help` instance that shows an argument only in the extended help display.
  public static var hidden: ArgumentHelp {
    ArgumentHelp(visibility: .hidden)
  }

  /// A `Help` instance that hides an argument from the extended help display.
  public static var `private`: ArgumentHelp {
    ArgumentHelp(visibility: .private)
  }
}

extension ArgumentHelp: ExpressibleByStringInterpolation {
  public init(stringLiteral value: String) {
    self.abstract = value
  }
}

// MARK: - Deprecated API
extension ArgumentHelp {
  /// A Boolean value indicating whether this argument should be shown in
  /// the extended help display.
  @available(*, deprecated, message: "Use visibility level instead.")
  public var shouldDisplay: Bool {
    get {
      return visibility.base == .default
    }
    set {
      visibility = newValue ? .default : .hidden
    }
  }

  /// Creates a new help instance.
  @available(*, deprecated, message: "Use init(_:discussion:detailedDiscussion:valueName:visibility:) instead.")
  public init(
    _ abstract: String = "",
    discussion: String = "",
    valueName: String? = nil,
    shouldDisplay: Bool)
  {
    self.init(
      abstract,
      discussion: discussion,
      detailedDiscussion: "",
      valueName: valueName,
      visibility: shouldDisplay ? .default : .hidden)
  }
}
