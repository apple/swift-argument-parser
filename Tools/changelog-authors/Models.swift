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

struct Comparison: Equatable, Codable {
  var commits: [Commit]
}

struct Commit: Equatable, Codable {
  var sha: String
  var author: Author
}

struct Author: Equatable, Codable {
  var login: String
  var htmlURL: String
  
  enum CodingKeys: String, CodingKey {
    case login
    case htmlURL = "html_url"
  }
  
  var inlineLink: String {
    "[\(login)]"
  }
}

