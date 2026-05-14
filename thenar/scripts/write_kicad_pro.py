#!/usr/bin/env python3
"""Generate a minimal KiCad project (.kicad_pro) alongside a .kicad_pcb.

Ergogen emits only .kicad_pcb files. KiCad's launcher opens projects, so
without a sibling .kicad_pro the launcher errors out and you have to use
pcbnew directly. This script writes a .kicad_pro with sensible defaults
for hand-routed two-layer split keyboard PCBs:

    Default class:  0.25 mm tracks, 0.6 mm vias, 0.2 mm clearance
    Power class:    0.40 mm tracks, 0.8 mm vias        (VCC, GND, BAT+, RAW)
    Min track:      0.20 mm
    Min via:        0.60 mm drill 0.30 mm
    Min clearance:  0.20 mm

These are JLCPCB-friendly (their standard 2-layer minimums are 0.127 mm
track / 0.127 mm clearance, so we are comfortably above them).

Usage:
    write_kicad_pro.py <path/to/board.kicad_pcb>
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


POWER_NETS = ["VCC", "GND", "BAT+", "RAW", "VBUS"]


def project(pcb_basename: str) -> dict:
    return {
        "meta": {
            "filename": f"{pcb_basename}.kicad_pro",
            "version": 3,
        },
        "board": {
            "design_settings": {
                "rules": {
                    "min_clearance": 0.2,
                    "min_track_width": 0.2,
                    "min_via_diameter": 0.6,
                    "min_through_hole_diameter": 0.3,
                    "min_hole_clearance": 0.25,
                    "min_hole_to_hole": 0.25,
                },
                "track_widths": [0.0, 0.25, 0.4],
                "via_dimensions": [
                    {"diameter": 0.0, "drill": 0.0},
                    {"diameter": 0.6, "drill": 0.3},
                    {"diameter": 0.8, "drill": 0.4},
                ],
                "defaults": {
                    "board_outline_line_width": 0.1,
                    "copper_line_width": 0.2,
                    "copper_text_size_h": 1.5,
                    "copper_text_size_v": 1.5,
                    "copper_text_thickness": 0.3,
                    "silk_line_width": 0.15,
                    "silk_text_size_h": 1.0,
                    "silk_text_size_v": 1.0,
                    "silk_text_thickness": 0.15,
                },
            },
        },
        "net_settings": {
            "classes": [
                {
                    "name": "Default",
                    "clearance": 0.2,
                    "track_width": 0.25,
                    "via_diameter": 0.6,
                    "via_drill": 0.3,
                    "microvia_diameter": 0.3,
                    "microvia_drill": 0.1,
                    "diff_pair_gap": 0.25,
                    "diff_pair_width": 0.2,
                },
                {
                    "name": "Power",
                    "clearance": 0.2,
                    "track_width": 0.4,
                    "via_diameter": 0.8,
                    "via_drill": 0.4,
                    "nets": POWER_NETS,
                },
            ],
        },
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    pcb = Path(sys.argv[1])
    if not pcb.is_file():
        print(f"error: not a file: {pcb}", file=sys.stderr)
        return 1
    pro = pcb.with_suffix(".kicad_pro")
    pro.write_text(json.dumps(project(pcb.stem), indent=2) + "\n")
    print(f"wrote {pro}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
