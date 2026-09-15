#!/usr/bin/env python3
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Argument Parser open source project
##
## Copyright (c) 2026 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
##
##===----------------------------------------------------------------------===##
"""Exercise generated completions in real shell line editors; Python stdlib only."""

import argparse
import json
import os
import pty
import select
import shlex
import shutil
import signal
import subprocess
import tempfile
import time
from pathlib import Path


def complete(shell, executable, script, case, directory):
    result = directory / "line"
    ready = directory / "ready"
    for path in (result, ready):
        path.unlink(missing_ok=True)
    pid, terminal = pty.fork()
    if pid == 0:
        os.chdir(directory)
        os.environ["TERM"] = "xterm"
        os.environ["PATH"] = str(executable.parent) + os.pathsep + os.environ["PATH"]
        os.environ["LC_ALL"] = "C"
        args = {
            "bash": ["--noprofile", "--norc", "-i"],
            "zsh": ["-f", "-i"],
            "fish": ["--no-config", "-i"],
        }
        os.execv(shutil.which(shell), [shell, *args[shell]])
    transcript = bytearray()

    def wait_for(path):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if path.exists():
                return
            if select.select([terminal], [], [], 0.02)[0]:
                chunk = os.read(terminal, 65536)
                transcript.extend(chunk)
                if b"\x1b[0c" in chunk:
                    os.write(terminal, b"\x1b[?1;2c")
        raise AssertionError(f'{shell}: timeout\n{transcript.decode(errors="replace")}')

    try:
        quoted_script = shlex.quote(str(script))
        if shell == "bash":
            setup = f"""PS1=''; bind 'set editing-mode emacs'; source {quoted_script}
bind '"\\C-g": "\\C-aprintf %s \\"\\C-e\\" > line\\n"'
"""
        elif shell == "zsh":
            setup = f"""PS1=''; autoload -Uz compinit; compinit -D; bindkey -e
source {quoted_script}
_capture_line() {{ print -rn -- "$BUFFER" > line; }}
zle -N _capture_line; bindkey '^G' _capture_line
"""
        else:
            setup = f"""function fish_prompt; end; source {quoted_script}
bind \\cg 'printf "%s" (commandline) > line'
"""
        os.write(terminal, (setup + "touch ready\n").encode())
        wait_for(ready)
        before, after = case["line"].split("<TAB>")
        os.write(terminal, (before + after).encode())
        os.write(terminal, b"\x1b[D" * len(after))
        os.write(terminal, b"\t\x07")
        wait_for(result)
        actual = result.read_text().rstrip()
        expected = case["expected"]
        if isinstance(expected, dict):
            expected = expected[shell]
        assert (
            actual == expected
        ), f"{shell}: {case['line']!r}: expected {expected!r}, got {actual!r}"
    finally:
        os.kill(pid, signal.SIGHUP)
        os.close(terminal)
        os.waitpid(pid, 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bin-dir", required=True, type=Path)
    parser.add_argument("--case", type=int, choices=range(3))
    parser.add_argument("--shell", choices=["bash", "zsh", "fish"], action="append")
    args = parser.parse_args()
    executable = args.bin_dir.resolve() / "math"
    cases = json.loads(Path(__file__).with_name("cases.json").read_text())
    if args.case is not None:
        cases = [cases[args.case]]
    shells = args.shell or ["bash", "zsh", "fish"]
    for shell in shells:
        if shutil.which(shell) is None:
            parser.error(
                f"{shell} is required; install it or select available shells "
                "with --shell"
            )
    count = 0
    failures = 0
    with tempfile.TemporaryDirectory() as temporary:
        directory = Path(temporary)
        for shell in shells:
            script = directory / f"math.{shell}"
            script.write_bytes(
                subprocess.check_output(
                    [executable, "--generate-completion-script", shell]
                )
            )
            for case in cases:
                try:
                    complete(shell, executable, script, case, directory)
                except AssertionError as error:
                    print(f"FAIL {error}", flush=True)
                    failures += 1
                    continue
                print(f"PASS {shell}: {case['line']} -> {case['expected']}", flush=True)
                count += 1
    print(f"{count} shell completion fixtures passed, {failures} failed")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
