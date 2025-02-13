#!/bin/sh
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Argument Parser open source project
##
## Copyright (c) 2025 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
##
##===----------------------------------------------------------------------===##

# Move to the project root
cd "$(dirname "$0")" || exit
cd ..
echo "Formatting 'Sources/' and 'Tests/' from $(pwd)"

# Run the format / lint commands
swift format -ir Sources Tests && swift format lint -r --strict Sources Tests
