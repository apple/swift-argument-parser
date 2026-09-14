# Shell completion fixtures

These fixtures use the `ParsableCommand` hierarchy in `Examples/math/Math.swift`:
`Math` defaults to `Math.Add`, whose option group defines `--hex-output`.
`Math.Statistics.Average` supplies the nested `--kind` value completion control.

Build the example and run with Python 3 and bash, zsh and fish installed:

```sh
swift build --product math
python3 Tests/CompletionTests/test_completions.py --bin-dir "$(swift build --show-bin-path)"
```

Use `--shell bash` (repeatable) to run a subset. Missing requested shells fail
explicitly. The runner has no Python package dependencies and is for POSIX hosts.

Each row in `cases.json` gives the command line, the Tab/cursor location, and the
expected resulting line. The runner generates the completion script using the
built example, starts a clean interactive shell in a pseudoterminal, presses Tab,
and reads the shell's line buffer. It never executes the completed command.
Trailing shell-added whitespace is ignored; internal spacing is compared exactly.
Zsh adds a space before an existing suffix, so that fixture records its result
separately. The terminal answers fish's primary-device query to avoid its startup
capability-detection timeout.

The omitted-default cases fail with the original completion scripts. The nested
value case guards dispatch to an explicitly selected command. The test does not
replace the existing generated-script snapshots or Swift unit tests.
