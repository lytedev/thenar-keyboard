#!/usr/bin/env python3
"""Autoroute a scaffold .kicad_pcb with freerouting.

Pipeline:

    LoadBoard(input)
        |
    [strip footprints that crash DSN export]
        |
    ExportSpecctraDSN -> board.dsn
        |
    freerouting -de board.dsn -do board.ses -mp <passes>
        |
    LoadBoard(input) again (fresh, unstripped)
        |
    ImportSpecctraSES(board, board.ses)
        |
    SaveBoard(output)

Why the strip step:

KiCad's Specctra DSN exporter silently returns False on certain
ergogen-generated footprints. Two known offenders in this project:

  - text.js  emits a "footprint" with zero pads (just silkscreen text).
    DSN export bails when it walks the footprint and finds no pads to
    enumerate.
  - battery.js uses the module name `lib:niceview_headers` (a copy-paste
    leftover from when it was forked off the niceview footprint). DSN
    appears to choke on this; renaming the module or switching footprint
    fixes it.

Rather than mutate the design, we strip these footprints from a working
copy of the board for the DSN trip only. Freerouting routes the rest,
and SES import only adds copper traces — the text/battery footprints
in the original board are unaffected.

Usage:
    autoroute.py <input.kicad_pcb> <output.kicad_pcb> [<passes>]

Defaults to 50 passes. More passes = cleaner routing at higher cost.
10-30 is fast and ugly, 50-100 is reasonable for a keyboard, 200+ has
diminishing returns.

Must be run with KiCad's `pcbnew` Python module on PYTHONPATH and the
`freerouting` binary on PATH.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

import pcbnew


# Module names (FPID library item name) that crash DSN export.
DSN_BLOCKLIST = {
    "lib:text",
    "lib:niceview_headers",  # this is actually the battery footprint
}


def strip_dsn_breakers(board: "pcbnew.BOARD") -> int:
    removed = 0
    for fp in list(board.GetFootprints()):
        fpid = fp.GetFPID()
        full_name = f"{fpid.GetLibNickname()}:{fpid.GetLibItemName()}"
        item_name = str(fpid.GetLibItemName())
        if full_name in DSN_BLOCKLIST or f"lib:{item_name}" in DSN_BLOCKLIST:
            board.Remove(fp)
            removed += 1
    return removed


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

        # Pass 1: strip DSN-incompatible footprints, export DSN.
        board = pcbnew.LoadBoard(str(input_pcb))
        stripped = strip_dsn_breakers(board)
        print(f"[autoroute] stripped {stripped} DSN-incompatible footprints", flush=True)

        if not pcbnew.ExportSpecctraDSN(board, str(dsn)):
            print("error: DSN export failed even after stripping known offenders.",
                  file=sys.stderr)
            return 1
        print(f"[autoroute] DSN -> {dsn} ({dsn.stat().st_size} bytes)", flush=True)

        # Pass 2: run freerouting.
        print(f"[autoroute] running freerouting ({passes} passes) ...", flush=True)
        subprocess.run(
            ["freerouting", "-de", str(dsn), "-do", str(ses), "-mp", str(passes)],
            check=True,
        )
        if not ses.is_file():
            print(f"error: freerouting did not produce {ses}", file=sys.stderr)
            return 1
        print(f"[autoroute] SES -> {ses} ({ses.stat().st_size} bytes)", flush=True)

        # Pass 3: re-load original board (still has text + battery), import SES.
        board2 = pcbnew.LoadBoard(str(input_pcb))
        if not pcbnew.ImportSpecctraSES(board2, str(ses)):
            print("error: SES import failed", file=sys.stderr)
            return 1
        pcbnew.SaveBoard(str(output_pcb), board2)
        print(f"[autoroute] saved {output_pcb}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
