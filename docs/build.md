# Build Guide

> **⚠️ This guide is LLM-generated and has not been verified by an actual
> build.** It was produced by Claude by adapting the upstream
> [corax build guide](https://github.com/dnlbauer/corax-keyboard/blob/main/docs/BuildGuide.md) —
> rewording the prose, updating counts (54 → 56 keys, 28 hotswaps + 29
> diodes per side), and replacing the upstream's image-per-step photos
> with text descriptions. The procedural content is paraphrased from the
> upstream guide rather than independently verified. Treat it as a
> starting point; expect to cross-reference the upstream guide and other
> ZMK split builds, and submit corrections after your first build.
>
> TODO: Replace prose with photos at each step. Sections for the Nice!View
> display and the 3D-printed case are still unwritten — the upstream guide
> left them as TODOs too.

Thenar's assembly is mechanically identical to the corax — same reversible
PCB, same MCU/scrollwheel/display layout — it just has one extra switch
position per half on the outermost column.

---

## Disclaimer

This guide is written from the perspective of someone who has already built
some keyboards. It is probably not very beginner-friendly. There are many
tricks and techniques for soldering and assembling keyboards that are not
covered in detail. If this is your first build, I strongly recommend reading
one or two more comprehensive guides on other keyboards first. A great one
to start with is the Sofle guide:
<https://josefadamcik.github.io/SofleKeyboard/build_guide_choc.html>

## PCB routing (one-time, before you can order)

> **⚠️ The committed PCB in `thenar/routed/` is currently a verbatim copy
> of the ergogen scaffold — it has all the footprints placed but no copper
> routing.** Building gerbers from it today produces an unfabricatable
> board. Someone has to route the traces by hand in KiCad before any
> useful gerbers can be produced. See `thenar/routed/README.md` for
> current status.

If you are the one doing the routing, see the dedicated
[routing guide](./routing.md) for the step-by-step. The short
version:

```sh
nix build .#scaffold
# Open result/pcbs/keyboard.kicad_pcb in KiCad and route every net.
# Save your routed version over thenar/routed/keyboard.kicad_pcb.
# (Repeat for switchplate if any changes are needed.)
nix flake check        # confirms footprint placement still matches the scaffold
```

If someone else has already routed and committed (the normal case once
this stabilises): skip this section, go straight to ordering.

## Ordering PCBs

Build the gerber zip from the flake:

```sh
nix build .#gerbers-zip
```

`result/thenar-gerbers.zip` is the file you upload to your PCB fab. I
recommend [JLCPCB](https://jlcpcb.com/) with these settings:

|                         |                     |
|-------------------------|---------------------|
| Layers                  | 2                   |
| PCB Thickness           | 1.6 mm              |
| Surface Finish          | LeadFree HASL       |
| Via Covering            | Tented              |
| Board Outline Tolerance | +/- 0.2 mm (Regular)|

## Building the keyboard

You need two PCBs — one for each hand. The PCB is reversible: the same
board is used for both halves, and which face of the board ends up facing
up (toward your fingers) determines whether it's the left or right half.

Two pieces of jargon to keep straight:

- The **up side** is the face that ends up pointing upward in the
  finished keyboard — the side your fingers see (through the switchplate
  and keycaps). Switches, MCU, battery, scrollwheel, reset, and screen
  all live on this face.
- The **down side** is the face that ends up pointing at your desk.
  Hotswap sockets, diodes, on/off switch, and jumpers live here.

To tell which face should be up for which hand, look at the silkscreen:

- On the left half, the up side has **"Left Hand Up"** silkscreened on it.
- On the right half, the up side has **"Right Hand Up"** silkscreened on it.

The opposite face of each is the down side. Before you start, mark the
intended up face of each PCB with tape or a post-it. Check before every
step that you are working on the correct side.

### Jumpers

There are **31 jumpers to bridge per half**, in three groups (counts
verified against the ergogen output):

- **MCU (Nice!Nano): 24** — two chevron jumpers per pin row (one on the
  left of the module, one on the right), 12 rows.
- **Display (Nice!View): 4** — one per display pin except the center
  VCC pin, which is the same net on both sides and has no jumper.
- **Scrollwheel (encoder): 3** — ENCA, ENCB, GND, next to the encoder
  footprint.

They make the MCU/display/encoder footprints reusable between the two
halves by letting you pick which side connects each net.

**Solder the jumpers ONLY on the down side of the PCB.** That is: when
building the left half (up side labelled "Left Hand Up"), solder the
jumpers on the "Right Hand Up" side. This is critical — soldering on
the wrong side will not work, and on the MCU jumpers in particular it
can short pins together and destroy the Nice!Nano on power-up.

The encoder group has jumper pads on both faces (three per face); the
same rule applies — bridge only the three on the down side and leave
the up-side group open. The up-side group is the other half's wiring.

Bridge each jumper with a small blob of solder across the two pads.

### MCU sockets

Solder the 12-pin sockets for the Nice!Nano. The sockets go on the up
side. A useful trick is to tape the sockets in position from the up
side, flip the board, and solder them from the down side while the tape
holds them flush.

If you want the LiPo battery to fit between the PCB and the MCU later,
use low-profile sockets (e.g. 3DS1002-01-1\*20V13-JK by CONNFLY) — and
see Splitkb's mounting guide for a thorough walkthrough of how to height
the MCU sockets correctly:
<https://docs.splitkb.com/hc/en-us/articles/360011263059>

### On/Off switch and reset button

The on/off slider switch (C128955) goes on the **down side** of the
board. This leaves clearance on the up side for the battery to sit
between the PCB and the MCU. The switch has 7 legs but only the 3
marked legs are electrically required — soldering the other tabs as
mechanical support is optional.

The 2-pin reset button goes on the **up side**: insert it from the up
side and solder the legs on the down side. Orientation does not matter.

### Scrollwheel

Before soldering the EVQWGD001 encoder, you need to trim some of its
legs and tabs so it fits the PCB cleanly:

- Cut off the foot on the left side of the encoder (looking at the
  encoder from the wheel side) — there is no matching hole for it on
  the PCB.
- Trim the overhang tabs along the long right edge of the encoder. The
  signal pins alone are sturdy enough to hold it in place, and trimming
  these makes the encoder much easier to seat without flexing or
  snapping a pin.

Place the encoder on the board (up side) and solder its pins from
the down side.

### Hotswap sockets and diodes

There are **28 Kailh Choc v1 hotswap sockets** and **29 diodes** (1N4148W
SMD) per side — one diode per switch plus one for the scrollwheel. Both
the sockets and the diodes are mounted on the **down side** of the board.

Diode orientation matters. Each 1N4148W has a marking (an arrow or a
white line) on one end indicating the cathode. Align that mark with the
arrow on the silkscreen for each diode footprint. If you are unsure how
to read diode polarity, look it up before placing any — flipped diodes
will silently break the matrix for the affected key.

Workflow that tends to work well: tin one pad of each footprint first
(diodes and hotswaps both), then place the part with tweezers and
reflow that pad to anchor it, then solder the remaining pad(s). For
the hotswaps, press the socket flat against the PCB while reflowing
the anchor pad — gaps cause inconsistent key heights and bad switch
seating.

### Battery

Solder the LiPo battery (301230, 110 mAh) to the up-side battery pads
below the MCU footprint. The pads are labelled `+` and `-` on the
silkscreen; black wire goes to `-`, red wire goes to `+`. Double-check
polarity with a multimeter before powering on — a reversed LiPo will
damage the Nice!Nano (and possibly catch fire).

The battery is intended to sit on the up side, tucked under the MCU.
You can mount it on the down side instead if you prefer; the pads work
either way as long as polarity matches the silkscreen.

### MCU

Add the Nice!Nano and solder the pins on the MCU side. The MCU sits on
the **up side, facing down** (components toward the PCB). If you
chose low-profile sockets, there should be enough room for the battery
to live underneath. If not, position the pins so the gap is large
enough — solder the first and last pin to set the height, check
clearance, then solder the rest.

### Switches and keycaps

Snap the Kailh Choc v1 switches (PG1350) into the hotswap sockets from
the up side. If you are using a switchplate, install it before the
switches — the switches clip into the plate first, then the whole
assembly presses down into the sockets.

Add keycaps.

## Display (Nice!View)

TODO

## 3D printed case

TODO — and note: the upstream corax54 case will not fit thenar without
modification, because the outer column has an extra key. Either redesign
from `outlines/case.dxf` (produced by `nix build .#pcbs`) or extend the
upstream case in CAD.
