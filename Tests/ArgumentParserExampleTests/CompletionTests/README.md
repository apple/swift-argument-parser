# Shell completion fixtures

These fixtures use the `ParsableCommand` hierarchy in `Examples/math/Math.swift`:
`Math` defaults to `Math.Add`, whose option group defines `--hex-output`.
`Math.Statistics.Average` supplies the nested `--kind` value completion control.

Run the fixtures through Swift Testing:

```sh
swift test --filter CompletionExampleTests
```

`CompletionExampleTests` registers each shell/fixture pair as a separate test.
It runs installed bash, zsh and fish shells on macOS and Linux; Python 3 is
required for the PTY driver. The suite is disabled if Python 3 is unavailable.
Install all three shells to exercise all nine cases. The Python driver uses only
the standard library, and its output is included in Swift Testing failures.

To run the driver directly after building the math example:

```sh
python3 Tests/ArgumentParserExampleTests/CompletionTests/test_completions.py --bin-dir "$(swift build --show-bin-path)"
```

Use `--shell bash` (repeatable) to run a subset, and `--case 0` to run one fixture.
Missing explicitly requested shells fail.

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
