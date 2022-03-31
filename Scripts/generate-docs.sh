#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Argument Parser open source project
##
## Copyright (c) 2022 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
##
##===----------------------------------------------------------------------===##

# To keep the content on the GitHub Pages site up to date, this script should
# be run by someone with commit access to the 'gh-pages' branch after each 
# 'ArgumentParser' release.
#
# Destination URL:
# https://apple.github.io/swift-argument-parser/documentation/argumentparser/

set -eu

# A `realpath` alternative using the default C implementation
filepath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SWIFT_ARGUMENT_PARSER_ROOT="$(dirname $(dirname $(filepath $0)))"

# Set current directory to the repository root
cd "$SWIFT_ARGUMENT_PARSER_ROOT"

# Use git worktree to checkout the 'gh-pages' branch in a subdirectory
git fetch
git worktree add --checkout gh-pages origin/gh-pages

# Pretty print DocC JSON output so that it can be consistently diffed
export DOCC_JSON_PRETTYPRINT="YES"

# Generate documentation for the 'ArgumentParser' target and output it
# to the 'gh-pages' worktree directory.
export SWIFTPM_ENABLE_COMMAND_PLUGINS=1 
swift package \
    --allow-writing-to-directory "$SWIFT_ARGUMENT_PARSER_ROOT/gh-pages" \
    generate-documentation \
    --target ArgumentParser \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path swift-argument-parser \
    --output-path "$SWIFT_ARGUMENT_PARSER_ROOT/gh-pages"

# Save the current commit we've just built documentation from in a variable
CURRENT_COMMIT_HASH=`git rev-parse --short HEAD`

# Copy the redirect file into the 'gh-pages' directory
cp redirect.html gh-pages/index.html

# Commit and push our changes to the 'gh-pages' branch
cd gh-pages
git add .

if [ -n "$(git status --porcelain)" ]; then
    echo "Documentation changes found. Commiting the changes to the 'gh-pages' branch and pushing to origin."
    git commit -m "Update GitHub Pages documentation site to '$CURRENT_COMMIT_HASH'."
    git push origin HEAD:gh-pages
else
  # No changes found, nothing to commit.
  echo "No documentation changes found."
fi

# Delete the git worktree we created
cd ..
git worktree remove gh-pages
