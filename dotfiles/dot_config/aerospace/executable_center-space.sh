#!/usr/bin/env python3
"""Match yabai maybe_center_space using AeroSpace outer gaps.

Side and bottom pads follow the yabai table. outer.top stays 32 so Sketchybar
stays clear. Gaps are per monitor, based on that monitor's visible workspace.
"""

import fcntl
import os
import re
import subprocess
import sys
from pathlib import Path

CONFIG = Path.home() / ".config" / "aerospace" / "aerospace.toml"
LOCK = Path("/tmp/aerospace-center-space.lock")
BEGIN = "# BEGIN dynamic-gaps"
END = "# END dynamic-gaps"
INNER = 3
TOP = 40
DEFAULT_SIDE = 2
DEFAULT_BOTTOM = 2


def run(args):
    return subprocess.check_output(args, text=True).strip()


def screen_sizes():
    js = r"""
ObjC.import("AppKit");
var screens = $.NSScreen.screens;
var n = screens.count;
var lines = [];
for (var i = 0; i < n; i++) {
  var f = screens.objectAtIndex(i).frame;
  lines.push((i + 1) + " " + f.size.width + " " + f.size.height);
}
lines.join("\n");
"""
    out = subprocess.check_output(["osascript", "-l", "JavaScript", "-e", js], text=True)
    sizes = {}
    for line in out.splitlines():
        if not line.strip():
            continue
        idx, width, height = line.split()
        sizes[int(idx)] = (float(width), float(height))
    return sizes


def pads(width, height, tiled):
    ratio = int(width // height) if height else 0
    if ratio == 2:
        if tiled < 1:
            return 800, 90
        if tiled < 4:
            return 400, 90
        return 3, 60
    if ratio == 4:
        if tiled < 1:
            return 600, 3
        if tiled < 4:
            return 300, 3
        return 3, 3
    return 3, 3


def pattern(name):
    special = set(r"\.^$*+?{}[]|()")
    out = []
    for ch in name:
        if ch == '"':
            raise SystemExit(f"monitor name cannot be quoted in a gap pattern: {name}")
        if ch == "\\":
            out.append("\\\\\\\\")
        elif ch in special:
            out.append("\\\\" + ch)
        else:
            out.append(ch)
    return "^" + "".join(out) + "$"


def toml_gaps(entries):
    def value(field):
        parts = ", ".join(
            f'{{ monitor."{pat}" = {entry[field]} }}' for pat, entry in entries
        )
        default = DEFAULT_SIDE if field == "side" else DEFAULT_BOTTOM
        if not parts:
            return str(default)
        return f"[{parts}, {default}]"

    return "\n".join(
        [
            BEGIN,
            "[gaps]",
            f"inner.horizontal = {INNER}",
            f"inner.vertical = {INNER}",
            f"outer.top = {TOP}",
            f"outer.bottom = {value('bottom')}",
            f"outer.left = {value('side')}",
            f"outer.right = {value('side')}",
            END,
        ]
    )


def monitors():
    raw = run(
        [
            "aerospace",
            "list-monitors",
            "--format",
            "%{monitor-id}|%{monitor-name}|%{monitor-appkit-nsscreen-screens-id}",
        ]
    )
    sizes = screen_sizes()
    found = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        monitor_id, name, screen_id = line.split("|", 2)
        width, height = sizes[int(screen_id)]
        visible = run(
            ["aerospace", "list-workspaces", "--monitor", monitor_id, "--visible"]
        ).splitlines()
        workspace = visible[0].strip() if visible else ""
        tiled = 0
        if workspace:
            layouts = run(
                [
                    "aerospace",
                    "list-windows",
                    "--workspace",
                    workspace,
                    "--format",
                    "%{window-layout}",
                ]
            )
            tiled = sum(1 for item in layouts.splitlines() if item and item != "floating")
        side, bottom = pads(width, height, tiled)
        found.append((pattern(name), {"side": side, "bottom": bottom, "tiled": tiled, "ratio": int(width // height)}))
    return found


def main():
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    with LOCK.open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        text = CONFIG.read_text()
        match = re.search(rf"{re.escape(BEGIN)}.*?{re.escape(END)}", text, re.S)
        if not match:
            print("center-space: dynamic-gaps markers missing", file=sys.stderr)
            return 1
        block = toml_gaps(monitors())
        if match.group(0) == block:
            return 0
        updated = text[: match.start()] + block + text[match.end() :]
        tmp = CONFIG.with_suffix(".toml.tmp")
        tmp.write_text(updated)
        os.replace(tmp, CONFIG)
        print(block)
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
