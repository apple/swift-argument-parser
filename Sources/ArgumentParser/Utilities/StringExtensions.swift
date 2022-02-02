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

extension String {
  /// A naming convention as used for arguments, variables, types, etc.
  enum NamingConvention {
    /// The convention is camel case (that is, no separator characters are used
    /// and the first letter or initialism of each word is uppercase.)
    ///
    /// - Parameters:
    ///   - lowercaseFirstWord: Whether or not the first character or
    ///     initialism of the first word is uppercased. If `false`, produces
    ///     strings such as `"HelloWorld"`, `"URL"`, or `"NSMutableString"`. If
    ///     `true`, produces strings such as `"helloWorld"`, `"url"`, or
    ///     `"nsMutableString"`.
    case camelCase(lowercaseFirstWord: Bool)

    /// The convention is snake case (that is, words are separated by
    /// `separator`.
    ///
    /// - Parameters:
    ///   - separator: The character that separates words. The default, `"_"`,
    ///     produces strings such as `"snake_case"`, `"SNAKE_CASE"`, etc.
    case snakeCase(separator: Character = "_")

    /// The convention is equivalent to Swift's convention for variable names.
    ///
    /// This value is equal to `.camelCase(lowercaseFirstWord: true)`.
    static var swiftVariableCase: Self { .camelCase(lowercaseFirstWord: true) }

    /// This convention's separator character, if applicable.
    var separator: Character? {
      guard case let .snakeCase(separator: separator) = self else {
        return nil
      }
      return separator
    }
  }

  /// The auto-detected naming convention used in this string.
  ///
  /// If the convention used in this string could not be detected, the value of
  /// this property is `nil`.
  ///
  /// - Complexity: O(*n*) in the worst case where *n* is the number of
  ///   characters in `self`.
  var autoDetectedNamingConvention: NamingConvention? {
    let separator: Character?
    if contains("-") {
      separator = "-"
    } else if contains("_") {
      separator = "_"
    } else {
      separator = nil
    }

    if let separator = separator {
      if contains(where: { $0 != separator }) {
        // Snake case.
        return .snakeCase(separator: separator)
      } else {
        // Only contains the separator character, so treat as ambiguous.
        return nil
      }
    }

    // No auto-recognized separator, so assume camel case as long as at least
    // one uppercase letter is present in the string.
    if contains(where: \.isUppercase) {
      // If the first letter in the string is lowercase, then treat this string
      // as lowerCamelCase. Otherwise, UpperCamelCase.
      let isLowerCamelCase = (first(where: \.isLetter)?.isLowercase == true)
      return .camelCase(lowercaseFirstWord: isLowerCamelCase)
    }

    // This string's naming convention is ambiguous. For instance, "foo"
    // could be anything other than upper camel case.
    return nil
  }

  func wrapped(to columns: Int, wrappingIndent: Int = 0) -> String {
    let columns = columns - wrappingIndent
    guard columns > 0 else {
      // Skip wrapping logic if the number of columns is less than 1 in release
      // builds and assert in debug builds.
      assertionFailure("`columns - wrappingIndent` should be always be greater than 0.")
      return ""
    }

    var result: [Substring] = []
    
    var currentIndex = startIndex
    
    while true {
      let nextChunk = self[currentIndex...].prefix(columns)
      if let lastLineBreak = nextChunk.lastIndex(of: "\n") {
        result.append(contentsOf: self[currentIndex..<lastLineBreak].split(separator: "\n", omittingEmptySubsequences: false))
        currentIndex = index(after: lastLineBreak)
      } else if nextChunk.endIndex == self.endIndex {
        result.append(self[currentIndex...])
        break
      } else if let lastSpace = nextChunk.lastIndex(of: " ") {
        result.append(self[currentIndex..<lastSpace])
        currentIndex = index(after: lastSpace)
      } else if let nextSpace = self[currentIndex...].firstIndex(of: " ") {
        result.append(self[currentIndex..<nextSpace])
        currentIndex = index(after: nextSpace)
      } else {
        result.append(self[currentIndex...])
        break
      }
    }
    
    return result
      .map { $0.isEmpty ? $0 : String(repeating: " ", count: wrappingIndent) + $0 }
      .joined(separator: "\n")
  }

  /// Returns this string prefixed with another string using a given naming
  /// convention.
  ///
  /// - Parameters:
  ///   - prefix: The prefix to add.
  ///   - namingConvention: The naming convention to use when inserting
  ///     `prefix`.
  ///
  /// - Returns: A string derived from `prefix` and `self`.
  ///
  /// Examples:
  ///
  ///     "hello".addingPrefix("my", using: .snakeCase(separator: "-"))
  ///     // my-hello
  ///     "hello_there".addingPrefix("my", using: .snakeCase())
  ///     // my_hello_there
  ///     "hello-there".addingPrefix("my", using: .snakeCase(separator: "-"))
  ///     // my-hello-there
  ///     "helloThere".addingPrefix("my", using: .snakeCase)
  ///     // myHelloThere
  ///
  /// - Complexity: O(*n*) where *n* is the number of characters in `self`.
  func addingPrefix(_ prefix: String, using namingConvention: NamingConvention) -> String {
    return converted(from: namingConvention, to: namingConvention) { words in
      words.insert(prefix[prefix.startIndex ..< prefix.endIndex], at: 0)
    }
  }

  /// Converts this string from one naming convention to another.
  ///
  /// - Parameters:
  ///   - oldConvention: The naming convention already in use in `self`. This
  ///     convention is used when splitting `self` into words.
  ///   - newConvention: A new naming convention to which `self` will be
  ///     converted.
  ///   - wordsModifier: If not `nil`, a closure to call after the string has
  ///     been split but before it is rejoined. The closure may modify the word
  ///     list as needed.
  ///
  /// - Returns: A string derived from `self`, converted from one naming
  ///   convention to another.
  ///
  /// - Complexity: O(*n*) where *n* is the number of characters in `self`.
  ///
  /// If `oldConvention` is `nil`, `autoDetectedNamingConvention` is used
  /// instead. If that value is also `nil`, this function performs no conversion
  /// and returns `self`.
  ///
  /// Examples:
  ///
  ///     "myProperty".converted(to: .snakeCase())
  ///     // my_Property
  ///     "myProperty".converted(to: .snakeCase()).lowercased()
  ///     // my_property
  ///     "myURLProperty".converted(to: .snakeCase()).lowercased()
  ///     // my_url_property
  ///     "myURLProperty".converted(to: .snakeCase(separator: "-")).lowercased()
  ///     // my-url-property
  ///     "my_url_property".converted(to: .swiftVariableCase)
  ///     // myUrlProperty
  ///     "My_URL_propertY".converted(to: .swiftVariableCase)
  ///     // myURLProperty
  func converted(from oldConvention: NamingConvention? = nil, to newConvention: NamingConvention, modifyingWordsListUsing wordsModifier: ((inout [Substring]) -> Void)? = nil) -> String {
    // This function performs three operations:
    //
    // 1. It splits the string into "words" based on word boundaries determined
    //    by `oldConvention`.
    // 2. It offers the caller a chance to modify the list of "words" by calling
    //    `wordsModifier`.
    // 3. It rejoins the list of "words" back into a string using the rules of
    //    `newConvention`.
    //
    // NOTE: Even if the conventions are equal, perform the work since we may
    // need to normalize character cases.

    // Figure out the existing naming convention if the caller didn't supply
    // one. If one is not readily apparent, return self as documented.
    guard let oldConvention = oldConvention ?? autoDetectedNamingConvention else {
      return self
    }

    // STEP 1
    var words: [Substring]
    switch oldConvention {
    case .camelCase:
      let startIndex = startIndex
      let endIndex = endIndex

      var wordRanges = [Range<Index>]()
      var wordStartIndex = startIndex

      // Whether we should append a separator when we see a uppercase character.
      var separateOnUppercase = true
      let separator = newConvention.separator

      forEachIndex { i, character in
        var addWord = false
        if character.isUppercase {
          if separateOnUppercase {
            addWord = true
          }

          // If the next character is uppercase and the next-next character is
          // lowercase, like "L" in "URLSession", we should separate words.
          let nextIndex = index(after: i)
          separateOnUppercase = nextIndex < endIndex && self[nextIndex].isUppercase && self.index(after: nextIndex) < endIndex && self[self.index(after: nextIndex)].isLowercase

        } else {
          // If the character is `separator`, we do not want to insert another
          // separator when we see the next uppercase character.
          separateOnUppercase = character != separator
        }

        if addWord {
          wordRanges.append(wordStartIndex ..< i)
          wordStartIndex = i
        }
      }

      if let lastWordRange = wordRanges.last {
        // Add whatever remains uncaptured (might be empty.)
        wordRanges.append(lastWordRange.upperBound ..< endIndex)
      } else {
        // Nothing was captured. The whole string is one "word."
        wordRanges.append(startIndex ..< endIndex)
      }

      // Convert the captured ranges to substrings.
      words = wordRanges.lazy.filter { !$0.isEmpty }.map { self[$0] }

    case let .snakeCase(separator: separator):
      words = split(separator: separator, omittingEmptySubsequences: false)
    }

    // STEP 2
    wordsModifier?(&words)

    // STEP 3
    return words.joined(using: newConvention)
  }


  /// Returns the edit distance between this string and the provided target string.
  ///
  /// Uses the Levenshtein distance algorithm internally.
  ///
  /// See: https://en.wikipedia.org/wiki/Levenshtein_distance
  ///
  /// Examples:
  ///
  ///     "kitten".editDistance(to: "sitting")
  ///     // 3
  ///     "bar".editDistance(to: "baz")
  ///     // 1

  func editDistance(to target: String) -> Int {
    let rows = self.count
    let columns = target.count
    
    if rows <= 0 || columns <= 0 {
      return max(rows, columns)
    }
    
    var matrix = Array(repeating: Array(repeating: 0, count: columns + 1), count: rows + 1)
    
    for row in 1...rows {
      matrix[row][0] = row
    }
    for column in 1...columns {
      matrix[0][column] = column
    }
    
    for row in 1...rows {
      for column in 1...columns {
        let source = self[self.index(self.startIndex, offsetBy: row - 1)]
        let target = target[target.index(target.startIndex, offsetBy: column - 1)]
        let cost = source == target ? 0 : 1
        
        matrix[row][column] = Swift.min(
          matrix[row - 1][column] + 1,
          matrix[row][column - 1] + 1,
          matrix[row - 1][column - 1] + cost
        )
      }
    }
    
    return matrix.last!.last!
  }
  
  func indentingEachLine(by n: Int) -> String {
    let hasTrailingNewline = self.last == "\n"
    let lines = self.split(separator: "\n", omittingEmptySubsequences: false)
    if hasTrailingNewline && lines.last == "" {
      return lines.dropLast().map { String(repeating: " ", count: n) + $0 }
        .joined(separator: "\n") + "\n"
    } else {
      return lines.map { String(repeating: " ", count: n) + $0 }
        .joined(separator: "\n")
    }
  }
}

extension Sequence where Element: StringProtocol {
  /// Join a sequence of substrings according to a given naming convention.
  ///
  /// - Parameters:
  ///   - namingConvention: The naming convention to use when joining the
  ///     elements of `self`.
  ///
  /// - Returns: A string derived from the elements of `self`.
  ///
  /// - Complexity: O(*nm*) where *n* is the number of elements in `self` and
  ///   *m* is the average number of characters in each element.
  ///
  /// This function joins a sequence of strings or string-like values using the
  /// specified naming convention.
  ///
  /// When converting to `.camelCase`, individual letters will be uppercased or
  /// lowercased to match that convention. When converting to `.snakeCase`,
  /// individual letter cases are preserved.
  ///
  /// - SeeAlso: ``String.converted(from:to:modifyingWordsListUsing:)``
  func joined(using namingConvention: String.NamingConvention) -> String {
    switch namingConvention {
    case let .camelCase(lowercaseFirstWord: isLowerCamelCase):
      if isLowerCamelCase {
        // The first character should be lowercased and, if the entire first
        // word is an initialism, it should also be lowercased. (We can express
        // that as simply lowercasing the entire first word since splitting
        // should have followed case lines.) Otherwise lower camel case is the
        // same as upper camel case.
        guard let firstWord = first(where: { _ in true })?.lowercased() else {
          return ""
        }
        let theRest = dropFirst().joined(using: .camelCase(lowercaseFirstWord: false))
        return firstWord + theRest
      }

      // Leave initialisms alone, but otherwise uppercase the first character
      // and lowercase the rest.
      var result = ""
      let underestimatedCharacterCount = reduce(0, { $0 + $1.count })
      result.reserveCapacity(underestimatedCharacterCount)

      for word in self {
        if !word.contains(where: \.isLowercase) {
          // All uppercase.
          result += word
        } else if let firstCharacter = word.first {
          result += firstCharacter.uppercased()
          result += word.dropFirst().lowercased()
        }
      }

      return result

    case let .snakeCase(separator: separator):
      return String(joined(separator: String(separator)))
    }
  }
}

extension Collection {
  /// Iterate the elements of this collection, yielding both the index and value
  /// for each element.
  ///
  /// - Parameters:
  ///   - body: A closure to which this function will pass each index and
  ///     element in `self`.
  ///
  /// - Throws: Whatever is thrown by `body`.
  func forEachIndex(_ body: (Index, Element) throws -> Void) rethrows -> Void {
    let startIndex = startIndex
    let endIndex = endIndex

    // Iterate indexes manually instead of using `for i in indices`. `indices`
    // is not a lazy collection and may be expensive to construct.
    var i = startIndex
    while i < endIndex {
      try body(i, self[i])
      i = index(after: i)
    }
  }
}
