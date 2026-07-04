#!/usr/bin/env python3
"""Extract tagged point centres from ergogen's --debug points.yaml.

By default extracts `screw`-tagged points; pass a second argument to
extract a different tag (e.g. `mcu`, used by the bottom case to locate
the USB notch).

The switchplate PCB gets its mounting holes as `hole` footprints placed at
`screw`-tagged points, so they are not part of the switchplate DXF outline.
The 3D-printed plate needs them subtracted separately; this script prints an
OpenSCAD vector literal like

    [[86.070972,-71.2869486],[110.069226,-73.386595],...]

suitable for `openscad -D screw_positions=<output>`. Point coordinates in
points.yaml are in the same coordinate space as the outline DXFs.

Kept dependency-free (no pyyaml) so it runs under bare python3 in the nix
sandbox: it only needs the top-level point name, the indent-4 x/y scalars,
and the indent-8 `tags:` list directly under `meta:`.
"""
import re
import sys

XY_RE = re.compile(r"^'?([xy])'?:\s*(-?[0-9.]+)$")


def tagged_positions(path, tag):
    points = {}
    current = None
    in_tags = False
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip())
            stripped = line.strip()
            if indent == 0 and stripped.endswith(":"):
                current = points.setdefault(
                    stripped[:-1], {"x": None, "y": None, "tags": []}
                )
                in_tags = False
                continue
            if current is None:
                continue
            if indent == 4:
                in_tags = False
                m = XY_RE.match(stripped)
                if m:
                    current[m.group(1)] = float(m.group(2))
            elif indent == 8:
                in_tags = stripped == "tags:"
            elif in_tags and indent == 12 and stripped.startswith("- "):
                current["tags"].append(stripped[2:].strip())

    return [
        (p["x"], p["y"])
        for p in points.values()
        if tag in p["tags"] and p["x"] is not None and p["y"] is not None
    ]


def main():
    if len(sys.argv) not in (2, 3):
        print(f"usage: {sys.argv[0]} <points.yaml> [tag]", file=sys.stderr)
        return 2
    tag = sys.argv[2] if len(sys.argv) == 3 else "screw"
    positions = tagged_positions(sys.argv[1], tag)
    if not positions:
        print(f"error: no {tag}-tagged points found", file=sys.stderr)
        return 1
    print("[" + ",".join(f"[{x},{y}]" for x, y in positions) + "]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
