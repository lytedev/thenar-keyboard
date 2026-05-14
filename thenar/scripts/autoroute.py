#!/usr/bin/env python3
"""[BLOCKED] Autoroute a scaffold .kicad_pcb with freerouting.

Status: this does not currently work on the thenar PCB.

The thenar PCB inherits a "reversible" design pattern from upstream
corax: the MCU, display, and scrollwheel each have jumper pairs that
let the same physical PCB serve as either the left or right half,
depending on which jumpers are bridged. Electrically, each jumper
position has *two* nets assigned to it (e.g. one pad of the Nice!View
header is on net `NN_GND_SCL` — "Nice!Nano GND on one side, SCL on the
other"). KiCad's Specctra DSN exporter refuses to emit a design where
two nets share copper, so `pcbnew.ExportSpecctraDSN()` returns False
and produces no output file.

To make this work, the design would have to be flattened to a single
half first (pick left or right, replace each hybrid net with its
left-or-right-specific net, remove the unused jumper footprints), and
the autorouted result would only cover that half. The other half would
have to be mirrored or routed separately.

That is a meaningful project, not a quick automation. This script is
left in place as a starting point. If you want to pursue it:

1. Add a pre-processing pass that takes the scaffold PCB and rewrites
   hybrid nets (NN_*) to one side's actual nets, then removes the
   now-unused jumper footprints.
2. Call this script's existing pipeline on the flattened board.
3. Either accept "left half only" output, or write a post-process that
   mirrors the routing to produce a second .kicad_pcb for the right
   half.

If you got freerouting working, the pipeline below already handles the
ExportDSN -> freerouting -> ImportSES roundtrip.

Usage (when unblocked):
    autoroute.py <input.kicad_pcb> <output.kicad_pcb> [<passes>]
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

import pcbnew


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(__doc__, file=sys.stderr)
        return 2

    input_pcb = Path(sys.argv[1])
    output_pcb = Path(sys.argv[2])
    passes = int(sys.argv[3]) if len(sys.argv) == 4 else 50

    if not input_pcb.is_file():
        print(f"error: not a file: {input_pcb}", file=sys.stderr)
        return 1
    output_pcb.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        dsn = tmp / "board.dsn"
        ses = tmp / "board.ses"

        board = pcbnew.LoadBoard(str(input_pcb))
        if not pcbnew.ExportSpecctraDSN(board, str(dsn)):
            print(
                "error: DSN export failed. The thenar PCB is reversible and has\n"
                "       intentionally-shorted hybrid nets that KiCad will not\n"
                "       export. See this script's docstring for the workaround\n"
                "       (a flattening pass that hasn't been written yet).",
                file=sys.stderr,
            )
            return 1
        print(f"[autoroute] DSN -> {dsn} ({dsn.stat().st_size} bytes)", flush=True)

        print(f"[autoroute] running freerouting ({passes} passes) ...", flush=True)
        subprocess.run(
            ["freerouting", "-de", str(dsn), "-do", str(ses), "-mp", str(passes)],
            check=True,
        )
        if not ses.is_file():
            print(f"error: freerouting did not produce {ses}", file=sys.stderr)
            return 1

        board2 = pcbnew.LoadBoard(str(input_pcb))
        if not pcbnew.ImportSpecctraSES(board2, str(ses)):
            print("error: SES import failed", file=sys.stderr)
            return 1
        pcbnew.SaveBoard(str(output_pcb), board2)
        print(f"[autoroute] saved {output_pcb}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
