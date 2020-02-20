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
  func wrapped(to columns: Int, wrappingIndent: Int = 0) -> String {
    let columns = columns - wrappingIndent
    var result: [Substring] = []
    
    var currentIndex = startIndex
    
    while true {
      let nextChunk = self[currentIndex...].prefix(columns)
      if let lastLineBreak = nextChunk.lastIndex(of: "\n") {
        result.append(self[currentIndex..<lastLineBreak])
        currentIndex = index(after: lastLineBreak)
      } else if let lastSpace = nextChunk.lastIndex(of: " ") {
        result.append(self[currentIndex..<lastSpace])
        currentIndex = index(after: lastSpace)
      } else if let nextSpace = self[currentIndex...].firstIndex(of: " ") {
        result.append(self[currentIndex..<nextSpace])
        currentIndex = index(after: nextSpace)
      } else {
        if let lastSegment = result.last,
          lastSegment.count + self[currentIndex...].count < columns
        {
          result[result.count - 1] = self[lastSegment.startIndex...]
          break
        }
        
        result.append(self[currentIndex...])
        break
      }
    }
    
    return result
      .map { String(repeating: " ", count: wrappingIndent) + $0 }
      .joined(separator: "\n")
  }
  
  /// Returns this string prefixed using a camel-case style.
  ///
  /// Example:
  ///
  ///     "hello".addingIntercappedPrefix("my")
  ///     // myHello
  func addingIntercappedPrefix(_ prefix: String) -> String {
    guard let firstChar = first else { return prefix }
    return "\(prefix)\(firstChar.uppercased())\(self.dropFirst())"
  }
  
  /// Returns this string prefixed using kebab-, snake-, or camel-case style
  /// depending on what can be detected from the string.
  ///
  /// Examples:
  ///
  ///     "hello".addingPrefixWithAutodetectedStyle("my")
  ///     // my-hello
  ///     "hello_there".addingPrefixWithAutodetectedStyle("my")
  ///     // my_hello_there
  ///     "hello-there".addingPrefixWithAutodetectedStyle("my")
  ///     // my-hello-there
  ///     "helloThere".addingPrefixWithAutodetectedStyle("my")
  ///     // myHelloThere
  func addingPrefixWithAutodetectedStyle(_ prefix: String) -> String {
    if contains("-") {
      return "\(prefix)-\(self)"
    } else if contains("_") {
      return "\(prefix)_\(self)"
    } else if first?.isLowercase == true && contains(where: { $0.isUppercase }) {
      return addingIntercappedPrefix(prefix)
    } else {
      return "\(prefix)-\(self)"
    }
  }
  
  /// Returns a new string with the camel-case-based words of this string
  /// split by the specified separator.
  ///
  /// Examples:
  ///
  ///     "myProperty".convertedToSnakeCase()
  ///     // my_property
  ///     "myURLProperty".convertedToSnakeCase()
  ///     // my_url_property
  ///     "myURLProperty".convertedToSnakeCase(separator: "-")
  ///     // my-url-property
  func convertedToSnakeCase(separator: Character = "_") -> String {
    guard !isEmpty else { return self }
    // This algorithm expects the first character of the string to be lowercase,
    // per Swift API design guidelines. If it's an uppercase character instead,
    // add and strip an extra character at the beginning.
    // TODO: Fold this logic into the body of this method?
    guard first?.isUppercase == false else {
      return String(
        ("z" + self).convertedToSnakeCase(separator: separator)
          .dropFirst(2)
      )
    }
    
    var words : [Range<String.Index>] = []
    // The general idea of this algorithm is to split words on transition from
    // lower to upper case, then on transition of >1 upper case characters to
    // lowercase
    var cursor = startIndex
    
    // Find next uppercase character
    while let nextUpperCase = self[cursor...].dropFirst().firstIndex(where: { $0.isUppercase }) {
      words.append(cursor..<nextUpperCase)
      cursor = nextUpperCase
      
      // Find next lowercase character
      guard let nextLowerCase = self[cursor...].firstIndex(where: { $0.isLowercase }) else {
        // There are no more lower case letters. Just end here.
        break
      }
      
      // Is the next lowercase letter more than 1 after the uppercase? If so,
      // we encountered a group of uppercase letters that we should treat as
      // its own word
      let nextCharacterAfterCapital = self.index(after: nextUpperCase)
      if nextLowerCase != nextCharacterAfterCapital {
        // There was a range of >1 capital letters. Turn those into a word,
        // stopping at the capital before the lower case character.
        let beforeLowerIndex = self.index(before: nextLowerCase)
        words.append(nextUpperCase..<beforeLowerIndex)
        
        // Next word starts at the capital before the lowercase we just found
        cursor = beforeLowerIndex
      }
    }
    
    // Add the last word segment; there's no effect on the result if empty.
    words.append(cursor..<endIndex)
    
    return words.map { (range) in
      self[range].lowercased()
    }.joined(separator: String(separator))
  }
}
