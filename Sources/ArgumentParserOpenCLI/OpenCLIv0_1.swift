//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct OpenCLIv0_1: Codable, Equatable {
  public let opencli: String
  public let info: CliInfo
  public let conventions: Conventions?
  public let arguments: [Argument]?
  public let options: [Option]?
  public let commands: [Command]?
  public let exitCodes: [ExitCode]?
  public let examples: [String]?
  public let interactive: Bool?
  public let metadata: [Metadata]?

  public init(
    opencli: String, info: CliInfo, conventions: Conventions? = nil,
    arguments: [Argument]? = nil, options: [Option]? = nil,
    commands: [Command]? = nil, exitCodes: [ExitCode]? = nil,
    examples: [String]? = nil, interactive: Bool? = nil,
    metadata: [Metadata]? = nil
  ) {
    self.opencli = opencli
    self.info = info
    self.conventions = conventions
    self.arguments = arguments
    self.options = options
    self.commands = commands
    self.exitCodes = exitCodes
    self.examples = examples
    self.interactive = interactive
    self.metadata = metadata
  }

  public struct CliInfo: Codable, Equatable {
    public let title: String
    public let version: String
    public let summary: String?
    public let description: String?
    public let contact: Contact?
    public let license: License?

    public init(
      title: String, version: String, summary: String? = nil,
      description: String? = nil, contact: Contact? = nil,
      license: License? = nil
    ) {
      self.title = title
      self.version = version
      self.summary = summary
      self.description = description
      self.contact = contact
      self.license = license
    }
  }

  public struct Conventions: Codable, Equatable {
    public let groupOptions: Bool?
    public let optionSeparator: String?

    public init(groupOptions: Bool? = true, optionSeparator: String? = " ") {
      self.groupOptions = groupOptions
      self.optionSeparator = optionSeparator
    }
  }

  public struct Argument: Codable, Equatable {
    public let name: String
    public let required: Bool?
    public let arity: Arity?
    public let acceptedValues: [String]?
    public let group: String?
    public let description: String?
    public let hidden: Bool?
    public let metadata: [Metadata]?
    public let swiftArgumentParserFile: Bool?
    public let swiftArgumentParserDirectory: Bool?

    public init(
      name: String, required: Bool? = nil, arity: Arity? = nil,
      acceptedValues: [String]? = nil, group: String? = nil,
      description: String? = nil, hidden: Bool? = false,
      metadata: [Metadata]? = nil, swiftArgumentParserFile: Bool? = nil,
      swiftArgumentParserDirectory: Bool? = nil
    ) {
      self.name = name
      self.required = required
      self.arity = arity
      self.acceptedValues = acceptedValues
      self.group = group
      self.description = description
      self.hidden = hidden
      self.metadata = metadata
      self.swiftArgumentParserFile = swiftArgumentParserFile
      self.swiftArgumentParserDirectory = swiftArgumentParserDirectory
    }
  }

  public struct Option: Codable, Equatable {
    public let name: String
    public let required: Bool?
    public let aliases: [String]?
    public let arguments: [Argument]?
    public let group: String?
    public let description: String?
    public let recursive: Bool?
    public let hidden: Bool?
    public let metadata: [Metadata]?
    public let swiftArgumentParserRepeating: Bool?
    public let swiftArgumentParserFile: Bool?
    public let swiftArgumentParserDirectory: Bool?

    public init(
      name: String, required: Bool? = nil, aliases: [String]? = nil,
      arguments: [Argument]? = nil, group: String? = nil,
      description: String? = nil, recursive: Bool? = false,
      hidden: Bool? = false,
      metadata: [Metadata]? = nil, swiftArgumentParserRepeating: Bool? = nil,
      swiftArgumentParserFile: Bool? = nil,
      swiftArgumentParserDirectory: Bool? = nil
    ) {
      self.name = name
      self.required = required
      self.aliases = aliases
      self.arguments = arguments
      self.group = group
      self.description = description
      self.recursive = recursive
      self.hidden = hidden
      self.metadata = metadata
      self.swiftArgumentParserRepeating = swiftArgumentParserRepeating
      self.swiftArgumentParserFile = swiftArgumentParserFile
      self.swiftArgumentParserDirectory = swiftArgumentParserDirectory
    }
  }

  public struct Command: Codable, Equatable {
    public let name: String
    public let aliases: [String]?
    public let options: [Option]?
    public let arguments: [Argument]?
    public let commands: [Command]?
    public let exitCodes: [ExitCode]?
    public let description: String?
    public let hidden: Bool?
    public let examples: [String]?
    public let interactive: Bool?
    public let metadata: [Metadata]?

    public init(
      name: String, aliases: [String]? = nil, options: [Option]? = nil,
      arguments: [Argument]? = nil, commands: [Command]? = nil,
      exitCodes: [ExitCode]? = nil, description: String? = nil,
      hidden: Bool? = false, examples: [String]? = nil,
      interactive: Bool? = nil,
      metadata: [Metadata]? = nil
    ) {
      self.name = name
      self.aliases = aliases
      self.options = options
      self.arguments = arguments
      self.commands = commands
      self.exitCodes = exitCodes
      self.description = description
      self.hidden = hidden
      self.examples = examples
      self.interactive = interactive
      self.metadata = metadata
    }
  }

  public struct ExitCode: Codable, Equatable {
    public let code: Int
    public let description: String?

    public init(code: Int, description: String? = nil) {
      self.code = code
      self.description = description
    }
  }

  public struct Metadata: Codable, Equatable {
    public let name: String
    public let value: AnyCodable?

    public init(name: String, value: AnyCodable? = nil) {
      self.name = name
      self.value = value
    }
  }

  public struct Contact: Codable, Equatable {
    public let name: String?
    public let url: String?
    public let email: String?

    public init(name: String? = nil, url: String? = nil, email: String? = nil) {
      self.name = name
      self.url = url
      self.email = email
    }
  }

  public struct License: Codable, Equatable {
    public let name: String?
    public let identifier: String?

    public init(name: String? = nil, identifier: String? = nil) {
      self.name = name
      self.identifier = identifier
    }
  }

  public struct Arity: Codable, Equatable {
    public let minimum: Int?
    public let maximum: Int?

    public init(minimum: Int? = nil, maximum: Int? = nil) {
      self.minimum = minimum
      self.maximum = maximum
    }
  }

  public struct AnyCodable: Codable, Equatable {
    public let value: Any

    public init<T>(_ value: T?) {
      self.value = value ?? ()
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
      switch (lhs.value, rhs.value) {
      case let (lhs, rhs) as (Bool, Bool):
        return lhs == rhs
      case let (lhs, rhs) as (Int, Int):
        return lhs == rhs
      case let (lhs, rhs) as (Double, Double):
        return lhs == rhs
      case let (lhs, rhs) as (String, String):
        return lhs == rhs
      case let (lhs, rhs) as ([Any], [Any]):
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy {
          AnyCodable($0).value as? AnyHashable == AnyCodable($1).value
            as? AnyHashable
        }
      case let (lhs, rhs) as ([String: Any], [String: Any]):
        guard lhs.count == rhs.count else { return false }
        return lhs.allSatisfy { key, value in
          guard let rhsValue = rhs[key] else { return false }
          return AnyCodable(value).value as? AnyHashable == AnyCodable(rhsValue)
            .value as? AnyHashable
        }
      case (is ResultNil, is ResultNil):
        return true
      default:
        // Fallback to AnyHashable if possible
        return lhs.value as? AnyHashable == rhs.value as? AnyHashable
      }
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()

      if container.decodeNil() {
        self.init(ResultNil())
      } else if let bool = try? container.decode(Bool.self) {
        self.init(bool)
      } else if let int = try? container.decode(Int.self) {
        self.init(int)
      } else if let double = try? container.decode(Double.self) {
        self.init(double)
      } else if let string = try? container.decode(String.self) {
        self.init(string)
      } else if let array = try? container.decode([AnyCodable].self) {
        self.init(array.map { $0.value })
      } else if let dictionary = try? container.decode(
        [String: AnyCodable].self)
      {
        self.init(dictionary.mapValues { $0.value })
      } else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "AnyCodable value cannot be decoded")
      }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()

      switch value {
      case is ResultNil:
        try container.encodeNil()
      case let bool as Bool:
        try container.encode(bool)
      case let int as Int:
        try container.encode(int)
      case let double as Double:
        try container.encode(double)
      case let string as String:
        try container.encode(string)
      case let array as [Any]:
        try container.encode(array.map(AnyCodable.init))
      case let dictionary as [String: Any]:
        try container.encode(dictionary.mapValues(AnyCodable.init))
      default:
        let context = EncodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "AnyCodable value cannot be encoded")
        throw EncodingError.invalidValue(value, context)
      }
    }
  }

  private struct ResultNil: Codable, Equatable {}
}
