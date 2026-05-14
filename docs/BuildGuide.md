# Build Guide

TODO: Replace this draft with a verified, photographed walkthrough. The text
below is a best-guess procedure derived from the design itself (reversible
PCB, choc hotswap, Nice!Nano + Nice!View, EVQWGD001 scrollwheel) and from
standard ZMK wireless split practice. It should work, but nothing here has
been built and tested yet.

Topics still owed:
- Ordering PCBs (gerber location, recommended JLCPCB settings)
- BOM walkthrough (see `thenar/README.md`)
- Diode + hotswap socket placement (note the new num-row key on the outer
  column versus the upstream corax54)
- Nice!Nano + Nice!View headers
- Battery, slider switch, reset button
- Switchplate + 3D-printed case assembly
- Firmware flashing (link the thenar ZMK config repo once it exists)

---

# Draft build guide (untested)

## 0. Tools

- Fine-tip soldering iron (~300–320 °C for leaded, ~340–360 °C for lead-free)
- Solder (0.5–0.8 mm, leaded if you can get it)
- Flux pen
- Tweezers (curved + straight)
- Flush cutters
- Multimeter (continuity + diode mode)
- Small Phillips screwdriver (M2)
- Optional but recommended: PCB holder / helping hands, isopropyl alcohol +
  brush for cleaning flux

## 1. Order the PCBs

Gerbers are produced by the flake:

```sh
nix build .#gerbers-zip
```

The result symlink contains `thenar-gerbers.zip`. Upload it to your fab of
choice. Recommended JLCPCB settings (carried over from the upstream corax):

| Setting                 | Value               |
|-------------------------|---------------------|
| Layers                  | 2                   |
| PCB Thickness           | 1.6 mm              |
| Surface Finish          | LeadFree HASL       |
| Via Covering            | Tented              |
| Board Outline Tolerance | ±0.2 mm (Regular)   |

Order 2 boards (or 5 — minimum lot is usually 5; spares are nice).

The PCB is **reversible** — the same board is used for both halves, just
flipped. There is no left/right designator on the gerbers; you orient it
during assembly.

## 2. Identify front vs. back of each PCB

On each board, one side has the silkscreen text **"Left Hand Front"**, the
other has **"Right Hand Front"**. Pick one PCB to be the left half and one
to be the right half, then mark the front side of each with a piece of
tape so you don't lose track. Every component on a reversible PCB is
mounted with **the front facing you**.

## 3. Solder diodes

There is one 1N4148W SMD diode per switch (56) plus one for the scrollwheel
(57). The 58th in the BOM is a spare.

For each switch position there are two diode pads on the PCB — **one on the
front and one on the back**. You use only the pad on the side that matches
the front of the half you are currently building.

1. Orient the PCB front-side up.
2. For each switch location, identify the diode pad on this side.
3. Diodes are polarised: the cathode (line) goes toward the row net. The
   silkscreen has a matching line — align them.
4. Tin one pad with a small dot of solder. Place the diode with tweezers,
   reflow that pad to anchor it, then solder the second pad. Move on.
5. Repeat for the scrollwheel diode.

After all diodes on this half are placed, run a multimeter in diode mode
across each one to confirm polarity (~0.6 V drop in one direction, OL in
the other).

## 4. Solder Kailh Choc hotswap sockets

28 PG1350 hotswap sockets per half. Same drill as diodes:

1. Hotswaps go on the **back** of each half (i.e. the side opposite the
   "Front" silkscreen for that half).
2. Tin one of the two pads on the footprint.
3. Place the socket, reflow to anchor, then solder the second pad. The
   socket has a small notch — match it to the silkscreen outline.
4. Push the socket flush to the PCB while reflowing the first pad; gaps
   here cause keys to sit at different heights.

## 5. Solder the scrollwheel (EVQWGD001)

The scrollwheel footprint has jumpers that select rotation direction. On
this PCB they are pre-defined in ergogen, but each half still needs the
three jumpers on its **own front side** bridged:

- `ENCB` jumper (top)
- `GND` jumper (middle)
- `ENCA` jumper (bottom)

Bridge each with a tiny solder blob, side closest to the encoder body.
The encoder itself drops into the through-hole pads with the wheel
oriented toward the inner edge of the half. Solder the four mounting
tabs first to hold it square, then the signal pads.

## 6. Solder the slider switch (on/off)

The footprint accepts an SMD C128955 slider. Tin one pad, set the slider
on the footprint with tweezers, reflow, then solder the remaining pads
and the two ground tabs. This switch isolates the battery — without it
soldered in, the keyboard will not power on, even over USB.

## 7. Solder the reset button

Through-hole 2-pin tactile (3×6×4.3 mm). Goes on the front side near the
MCU footprint. Insert from the front, solder on the back, trim the legs
flush.

## 8. Mount Nice!Nano sockets

12-pin sockets per side, 2.54 mm spacing. The Nice!Nano sits front side,
**components facing down toward the PCB** (this is what "reverse: true"
in the ergogen config bakes in — the Pro Micro footprint is mirrored).

The Splitkb mounting guide referenced in the BOM is the canonical
reference for this step:
<https://docs.splitkb.com/hc/en-us/articles/360011263059>

Summary:

1. Push 12 header pins through the Nice!Nano from the **top** (so the
   plastic spacer ends up between board and pin tips), with long ends
   pointing down.
2. Drop the long ends through the socket on the PCB.
3. Place the matching socket on the PCB, sit the Nice!Nano on top.
4. Solder the **socket pins on the PCB side** first.
5. Flip, solder the **header pins to the Nice!Nano**.
6. Trim excess pin length.

Use **low-profile sockets** if you want the battery to fit underneath.
3DS1002-01-1\*20V13-JK (CONNFLY) is a known-good part.

## 9. (Optional) Nice!View headers

5-pin connector next to the Nice!Nano. Same procedure: pins through the
display module, drop through the PCB-side socket, solder PCB side first,
then display side. The display sits front-facing.

## 10. Battery

The 301230 (3.0×12×30 mm, ~110 mAh) LiPo tucks **under the Nice!Nano**.
Route the leads through the cutout near the slider switch and solder
to the `BAT+` / `BAT-` pads on the back of the PCB. Verify polarity with
a multimeter before powering on; reversing a LiPo will damage the
Nice!Nano.

If your battery has a JST connector, cut it off and solder the bare
leads directly — the PCB does not have a JST footprint.

## 11. Switchplate

The switchplate is a 1.2 mm thin plate with cutouts for every switch and
the scrollwheel. Two options:

- **3D printed:** export with `nix build .#switchplate-step`, slice at
  0.2 mm layer height, 0.4 mm walls, ~30% infill.
- **PCB-cut:** order from JLCPCB using the DXF in `nix build .#pcbs`
  (under `outlines/switchplate.dxf`). Spec 1.2 mm thickness explicitly.

The switchplate is sandwiched between the PCB and the case. Switches
clip into the switchplate first, then the whole stack is pressed into
the hotswap sockets.

## 12. Case

(Not yet designed for thenar — see the TODO at the top.) The upstream
corax case will not fit; the outline differs because of the extra
outer-column key. Plan on either:

- Designing a fresh case from the `outlines/case.dxf` produced by
  `nix build .#pcbs`, or
- Modifying the upstream corax54 case in Fusion / FreeCAD to extend the
  outer column.

Until then, the keyboard is usable as a bare PCB + switchplate sandwich
on silicone feet.

## 13. Flash the firmware

TODO: Once a ZMK config repo for thenar exists, link it here. Until then:

1. Plug the assembled half into a computer via USB-C.
2. Double-tap the reset button — the Nice!Nano enumerates as a USB
   mass-storage device named `NICENANO`.
3. Drag a compiled `*.uf2` onto the drive. It reboots and disappears.
4. Repeat for the other half.

Pair the two halves via ZMK's default bonding flow (hold reset on the
peripheral side after the central is awake).

## 14. Sanity check

With the case off, slide the power switch on:

- Nice!View (if installed) should show the ZMK splash.
- Tap a key — it should register on the connected host.
- Roll the scrollwheel — it should scroll.

If a key doesn't register: probe the matrix at the diode and the column
pin on the Nice!Nano with continuity mode. A cold solder joint on a
hotswap socket is the single most common failure.

Done. Enjoy.
