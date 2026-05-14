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

You need two PCBs — one for each hand. The PCB is reversible, so the same
board is used for both halves; the side you treat as the front determines
which hand the half becomes.

If this guide says "front side" and you are building the left half, you
work on the side that has **"Left Hand Front"** silkscreened on it. The
side with "Right Hand Front" is then the back side for that half. The
right half is the opposite: "Right Hand Front" is its front, "Left Hand
Front" is its back.

A good strategy is to mark the intended front side of each half with a
piece of tape or a post-it before you start. Check before every step that
you are working on the correct side.

### Jumpers

There are 12 jumpers on each side of the board, in three groups (MCU,
display, scrollwheel). They make the MCU/display/encoder footprints
reusable between the two halves by letting you pick which side connects
each net.

**Solder the jumpers ONLY on the back side of the PCB.** That is: when
building the left half (front labelled "Left Hand Front"), solder the
jumpers on the "Right Hand Front" side. This is critical — soldering on
the wrong side will not work, and on the MCU jumpers in particular it
can short pins together and destroy the Nice!Nano on power-up.

Bridge each jumper with a small blob of solder across the two pads.

### MCU sockets

Solder the 12-pin sockets for the Nice!Nano. The sockets go on the front
side. A useful trick is to tape the sockets in position from the front,
flip the board, and solder them from the back while the tape holds them
flush.

If you want the LiPo battery to fit between the PCB and the MCU later,
use low-profile sockets (e.g. 3DS1002-01-1\*20V13-JK by CONNFLY) — and
see Splitkb's mounting guide for a thorough walkthrough of how to height
the MCU sockets correctly:
<https://docs.splitkb.com/hc/en-us/articles/360011263059>

### On/Off switch and reset button

The on/off slider switch (C128955) goes on the **back side** of the
board. This leaves clearance on the front for the battery to sit between
the PCB and the MCU. The switch has 7 legs but only the 3 marked legs
are electrically required — soldering the other tabs as mechanical
support is optional.

The 2-pin reset button goes on the **front side**: insert it from the
front and solder the legs on the back. Orientation does not matter.

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

Place the encoder on the board (front side) and solder its pins from
the back.

### Hotswap sockets and diodes

There are **28 Kailh Choc v1 hotswap sockets** and **29 diodes** (1N4148W
SMD) per side — one diode per switch plus one for the scrollwheel. Both
the sockets and the diodes are mounted on the **back side** of the board.

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

Solder the LiPo battery (301230, 110 mAh) to the front-side battery pads
below the MCU footprint. The pads are labelled `+` and `-` on the
silkscreen; black wire goes to `-`, red wire goes to `+`. Double-check
polarity with a multimeter before powering on — a reversed LiPo will
damage the Nice!Nano (and possibly catch fire).

The battery is intended to sit on the front side, tucked under the MCU.
You can mount it on the back instead if you prefer; the pads work either
way as long as polarity matches the silkscreen.

### MCU

Add the Nice!Nano and solder the pins on the MCU side. The MCU sits on
the **front side, facing down** (components toward the PCB). If you
chose low-profile sockets, there should be enough room for the battery
to live underneath. If not, position the pins so the gap is large
enough — solder the first and last pin to set the height, check
clearance, then solder the rest.

### Switches and keycaps

Snap the Kailh Choc v1 switches (PG1350) into the hotswap sockets from
the front side. If you are using a switchplate, install it before the
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
