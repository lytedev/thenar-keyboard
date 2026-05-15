#!/usr/bin/env python3
"""Compare two routed .kicad_pcb files net-by-net.

Designed to compare a hand-routed PCB against an autoroute result so we
can see exactly where freerouting falls short:

- which nets it failed to route at all (left unconnected pads)
- which nets it routed but inefficiently (longer / more vias than the
  hand-routed version)
- where it agreed with the human

Usage:
    compare_routing.py <golden.kicad_pcb> <candidate.kicad_pcb>
"""

from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

import pcbnew


def stats_for(board: "pcbnew.BOARD") -> dict:
    """Per-net stats. Returns {netname: {length_mm, via_count, pad_count}}."""
    out: dict[str, dict] = defaultdict(
        lambda: {"length_mm": 0.0, "via_count": 0, "pad_count": 0}
    )
    for track in board.GetTracks():
        net = track.GetNet()
        name = net.GetNetname() if net else ""
        if not name:
            continue
        if track.Type() == pcbnew.PCB_VIA_T:
            out[name]["via_count"] += 1
        else:
            out[name]["length_mm"] += pcbnew.ToMM(track.GetLength())
    for pad in board.GetPads():
        net = pad.GetNet()
        name = net.GetNetname() if net else ""
        if not name:
            continue
        out[name]["pad_count"] += 1
    return dict(out)


def unconnected_pads_for(board: "pcbnew.BOARD") -> dict[str, int]:
    """Per-net count of unrouted pads. Uses the connectivity graph."""
    ratsnest = board.GetConnectivity()
    counts: dict[str, int] = defaultdict(int)
    for pad in board.GetPads():
        net = pad.GetNet()
        name = net.GetNetname() if net else ""
        if not name:
            continue
        # IsConnectedToNet tells us if this pad is connected to the rest
        # of its net via copper. The complement is unrouted.
        if not ratsnest.IsConnectedOnLayer(pad, pad.GetLayer()):
            counts[name] += 1
    return dict(counts)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    golden_path = Path(sys.argv[1])
    candidate_path = Path(sys.argv[2])

    print(f"Loading golden:    {golden_path}")
    golden = pcbnew.LoadBoard(str(golden_path))
    print(f"Loading candidate: {candidate_path}")
    candidate = pcbnew.LoadBoard(str(candidate_path))

    g_stats = stats_for(golden)
    c_stats = stats_for(candidate)

    all_nets = sorted(set(g_stats) | set(c_stats))

    # ---- summary
    g_total_len = sum(s["length_mm"] for s in g_stats.values())
    c_total_len = sum(s["length_mm"] for s in c_stats.values())
    g_total_vias = sum(s["via_count"] for s in g_stats.values())
    c_total_vias = sum(s["via_count"] for s in c_stats.values())

    print()
    print(f"{'metric':<25} {'golden':>12} {'candidate':>12} {'diff':>12}")
    print(f"{'-'*25} {'-'*12} {'-'*12} {'-'*12}")
    print(f"{'total trace length mm':<25} {g_total_len:>12.1f} {c_total_len:>12.1f} {c_total_len-g_total_len:>+12.1f}")
    print(f"{'total vias':<25} {g_total_vias:>12d} {c_total_vias:>12d} {c_total_vias-g_total_vias:>+12d}")
    print(f"{'nets present':<25} {len(g_stats):>12d} {len(c_stats):>12d}")

    # ---- per-net deltas, focus on candidate's deficits
    print()
    print("Nets where candidate is NOT shorter than golden (or unrouted):")
    print(f"{'net':<24} {'golden mm':>10} {'cand mm':>10} {'g vias':>7} {'c vias':>7} {'delta mm':>10}")
    print(f"{'-'*24} {'-'*10} {'-'*10} {'-'*7} {'-'*7} {'-'*10}")
    interesting = []
    for net in all_nets:
        g = g_stats.get(net, {"length_mm": 0, "via_count": 0, "pad_count": 0})
        c = c_stats.get(net, {"length_mm": 0, "via_count": 0, "pad_count": 0})
        if g["pad_count"] < 2:
            continue  # 1-pad nets (e.g. mounting holes) don't need routing
        if c["length_mm"] < g["length_mm"] * 0.9:
            # candidate is meaningfully shorter -> might be unrouted entirely
            interesting.append((net, g, c, "shorter (maybe unrouted)"))
        elif c["length_mm"] > g["length_mm"] * 1.15:
            interesting.append((net, g, c, "much longer"))
        elif c["via_count"] > g["via_count"] + 2:
            interesting.append((net, g, c, "extra vias"))
    interesting.sort(key=lambda r: r[2]["length_mm"] - r[1]["length_mm"])
    for net, g, c, why in interesting[:30]:
        print(f"{net:<24} {g['length_mm']:>10.1f} {c['length_mm']:>10.1f} "
              f"{g['via_count']:>7d} {c['via_count']:>7d} "
              f"{c['length_mm']-g['length_mm']:>+10.1f}  {why}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
