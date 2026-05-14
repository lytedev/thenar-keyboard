#!/usr/bin/env python3
"""Solve where to place ceoloide's display_nice_view footprint so its
through-holes land on the same physical spots the old corax-style
niceview occupied.

Approach:

  1. Read the OLD niceview position out of the pre-migration .kicad_pcb
     (footprint origin + rotation + local pad positions).
  2. Compute the absolute positions of each old pad. Those are the
     targets we want the new ceoloide pads to land on.
  3. Ceoloide's pads sit at known local positions in its footprint frame.
     Solve for (new_origin, new_rotation) such that each new pad lands
     on its corresponding target.
  4. Convert that absolute placement back into the ergogen `adjust`
     parameters (shift relative to the `mcu` anchor + rotate relative
     to the mcu's own rotation).

How ergogen composes the placement (derived empirically from the
pre-migration data):

  niceview_origin_abs = mcu.position + R(-mcu.rotation) * adjust.shift
  niceview_rotation   = mcu.rotation + adjust.rotate

i.e. the adjust.shift is interpreted in a frame rotated by -mcu.rotation
relative to the global frame.
"""

from __future__ import annotations

import math
from dataclasses import dataclass


# ---- Known values (read out of pre-migration thenar/routed/keyboard.kicad_pcb)

# Old niceview footprint placement.
OLD_ORIGIN = (170.570972, 95.086949)
OLD_ROT_DEG = 90  # the (at x y theta) value in the kicad_pcb

# Old niceview local pad layout (corax-style: vertical column at x=0).
# Order tracks the kicad_pcb pad-by-pad walk. Pad "1" appears twice in the
# old footprint - that is the shorting bug we're fixing - so we identify
# them by their y offset.
OLD_PADS_LOCAL = {
    "MOSI": (0.0, -5.08),   # was SDA, footprint pad 4
    "SCK":  (0.0, -2.54),   # was SCL, footprint pad 3
    "VCC":  (0.0,  0.00),                 # pad 2
    "GND":  (0.0,  2.54),                 # pad 1 (one of two)
    "CS":   (0.0,  5.08),                 # pad 1 (the other)
}

# mcu (ProMicro) anchor position - same source.
MCU_POS = (170.570972, 74.586949)
MCU_ROT_DEG = -90

# Ceoloide's display_nice_view local pad layout (horizontal row at y=16.7).
NEW_PADS_LOCAL = {
    "MOSI": (-5.08, 16.7),   # pad 1
    "SCK":  (-2.54, 16.7),   # pad 2
    "VCC":  ( 0.00, 16.7),   # pad 3
    "GND":  ( 2.54, 16.7),   # pad 4
    "CS":   ( 5.08, 16.7),   # pad 5
}


# ---- 2D geometry helpers

@dataclass
class Vec:
    x: float
    y: float

    def __add__(self, o: "Vec") -> "Vec":
        return Vec(self.x + o.x, self.y + o.y)

    def __sub__(self, o: "Vec") -> "Vec":
        return Vec(self.x - o.x, self.y - o.y)


def rotate(p: Vec, theta_deg: float) -> Vec:
    c = math.cos(math.radians(theta_deg))
    s = math.sin(math.radians(theta_deg))
    return Vec(p.x * c - p.y * s, p.x * s + p.y * c)


# ---- Solver

def old_pad_targets() -> dict[str, Vec]:
    """Absolute positions of the old niceview pads - our targets."""
    origin = Vec(*OLD_ORIGIN)
    return {
        signal: origin + rotate(Vec(*local), OLD_ROT_DEG)
        for signal, local in OLD_PADS_LOCAL.items()
    }


def solve_new_placement(targets: dict[str, Vec]) -> tuple[Vec, float]:
    """Find (origin, rotation_deg) so ceoloide's pads land at targets.

    The pads form a colinear row in the footprint frame. Pick MOSI and CS
    (the endpoints) to recover the rotation angle from the direction of
    the absolute row, then back out the origin from one pad's known
    target position.
    """
    p_mosi = targets["MOSI"]
    p_cs = targets["CS"]
    delta_abs = p_cs - p_mosi

    mosi_local = Vec(*NEW_PADS_LOCAL["MOSI"])
    cs_local = Vec(*NEW_PADS_LOCAL["CS"])
    delta_local = cs_local - mosi_local

    # Rotation that takes delta_local to delta_abs is angle(delta_abs) - angle(delta_local).
    theta_abs = math.atan2(delta_abs.y, delta_abs.x)
    theta_local = math.atan2(delta_local.y, delta_local.x)
    theta_deg = math.degrees(theta_abs - theta_local)

    origin = p_mosi - rotate(mosi_local, theta_deg)
    return origin, theta_deg


def verify(origin: Vec, theta_deg: float, targets: dict[str, Vec]) -> float:
    max_err = 0.0
    print("Verification (signal: target -> actual, error mm):")
    for signal, target in targets.items():
        local = Vec(*NEW_PADS_LOCAL[signal])
        actual = origin + rotate(local, theta_deg)
        err = math.hypot(actual.x - target.x, actual.y - target.y)
        max_err = max(max_err, err)
        print(f"  {signal:>4}: ({target.x:8.3f}, {target.y:8.3f}) "
              f"-> ({actual.x:8.3f}, {actual.y:8.3f})  err={err:.4f}")
    return max_err


def to_ergogen_adjust(origin: Vec, theta_deg: float) -> tuple[Vec, float]:
    """Express absolute placement as ergogen adjust params for `where: mcu`."""
    mcu = Vec(*MCU_POS)
    delta_abs = origin - mcu
    # niceview_origin = mcu + R(-mcu.rot) * shift, so shift = R(mcu.rot) * delta_abs.
    shift = rotate(delta_abs, MCU_ROT_DEG)
    rotate_relative = theta_deg - MCU_ROT_DEG
    # Normalise rotation to (-180, 180]
    while rotate_relative > 180:
        rotate_relative -= 360
    while rotate_relative <= -180:
        rotate_relative += 360
    return shift, rotate_relative


def main() -> None:
    targets = old_pad_targets()
    print("Old niceview pad positions (absolute mm):")
    for signal, p in targets.items():
        print(f"  {signal:>4}: ({p.x:8.3f}, {p.y:8.3f})")
    print()

    origin, theta = solve_new_placement(targets)
    print(f"New ceoloide footprint absolute placement:")
    print(f"  origin   = ({origin.x:.4f}, {origin.y:.4f})")
    print(f"  rotation = {theta:.2f} deg")
    print()

    max_err = verify(origin, theta, targets)
    print(f"\nMax pad placement error: {max_err:.4f} mm")
    print()

    shift, rot_rel = to_ergogen_adjust(origin, theta)
    print("Suggested ergogen config (paste into thenar/ergogen/config.yaml):")
    print()
    print("      niceview:")
    print("        what: display_nice_view")
    print("        where: mcu")
    print("        adjust:")
    print(f"          shift: [{shift.x:.4f}, {shift.y:.4f}]")
    print(f"          rotate: {rot_rel:.2f}")


if __name__ == "__main__":
    main()
