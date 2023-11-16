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

#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#elseif canImport(CRT)
import CRT
#elseif canImport(WASILibc)
import WASILibc
#endif

import CTools

enum Platform { }

// MARK: Shell
extension Platform {
  /// The name of the user's preferred shell, if detectable from the
  /// environment.
  static var shellName: String? {
#if os(Windows)
    return nil
#else
    
    return String(cString: shellPath())
#endif
  }
}

// MARK: Exit codes
#if os(Windows)
import func WinSDK.GetStdHandle
import func WinSDK.GetConsoleScreenBufferInfo
import let WinSDK.ERROR_BAD_ARGUMENTS
import let WinSDK.STD_OUTPUT_HANDLE
import struct WinSDK.CONSOLE_SCREEN_BUFFER_INFO
#endif

extension Platform {
  /// The code for successful exit.
  static var exitCodeSuccess: Int32 {
    EXIT_SUCCESS
  }
  
  /// The code for exit with a general failure.
  static var exitCodeFailure: Int32 {
    EXIT_FAILURE
  }
  
  /// The code for exit with a validation failure.
  static var exitCodeValidationFailure: Int32 {
#if os(Windows)
    return ERROR_BAD_ARGUMENTS
#elseif os(WASI)
    return EXIT_FAILURE
#else
    return EX_USAGE
#endif
  }
}

// MARK: Exit function

extension Platform {
  /// Complete execution with the given exit code.
  static func exit(_ code: Int32) -> Never {
#if canImport(Glibc)
    Glibc.exit(code)
#elseif canImport(Musl)
    Musl.exit(code)
#elseif canImport(Darwin)
    Darwin.exit(code)
#elseif canImport(CRT)
    ucrt._exit(code)
#elseif canImport(WASILibc)
    WASILibc.exit(code)
#endif
  }
}

// MARK: Standard error

extension Platform {
  /// A type that represents the `stderr` output stream.
  struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
      for byte in string.utf8 { putc(numericCast(byte), stderr) }
    }
  }
  
  /// The `stderr` output stream.
  static var standardError = StandardError()
}

// MARK: Terminal size

#if canImport(Glibc)
func ioctl(_ a: Int32, _ b: Int32, _ p: UnsafeMutableRawPointer) -> Int32 {
  ioctl(CInt(a), UInt(b), p)
}
#endif

extension Platform {
  /// The default terminal size.
  static var defaultTerminalSize: (width: Int, height: Int) {
    (80, 25)
  }
  
  /// Returns the current terminal size, or the default if the size is
  /// unavailable.
  static func terminalSize() -> (width: Int, height: Int) {
#if os(WASI)
    // WASI doesn't yet support terminal size
    return defaultTerminalSize
#elseif os(Windows)
    var csbi: CONSOLE_SCREEN_BUFFER_INFO = CONSOLE_SCREEN_BUFFER_INFO()
    guard GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi) else {
      return defaultTerminalSize
    }
    return (width: Int(csbi.srWindow.Right - csbi.srWindow.Left) + 1,
            height: Int(csbi.srWindow.Bottom - csbi.srWindow.Top) + 1)
#else
    var w = winsize()
#if os(OpenBSD)
    // TIOCGWINSZ is a complex macro, so we need the flattened value.
    let tiocgwinsz = Int32(0x40087468)
    let err = ioctl(STDOUT_FILENO, tiocgwinsz, &w)
#elseif canImport(Musl)
    let err = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
#else
    let err = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
#endif
    let width = Int(w.ws_col)
    let height = Int(w.ws_row)
    guard err == 0 else { return defaultTerminalSize }
    return (width: width > 0 ? width : defaultTerminalSize.width,
            height: height > 0 ? height : defaultTerminalSize.height)
#endif
  }
  
  /// The current terminal size, or the default if the width is unavailable.
  static var terminalWidth: Int {
    terminalSize().width
  }
}

