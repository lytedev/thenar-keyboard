# Thenar v1 PCB

The v1 redesign — chip-direct nRF52840 module + I/O expanders, designed
for JLCPCB PCBA assembly. See `docs/v1-design.md` (in the repo root) for
architectural decisions and BOM rationale.

This directory is a work-in-progress. The PCB hasn't been drawn yet.

## What's here

- **`ref-designguide-schematic/`** — vendored copy of
  `ebastler/zmk-designguide` (CERN-OHL-P licensed). A reference schematic
  showing tested wireless-keyboard topologies: USB-C + ESD, TP4056 charge
  IC, XC6206 LDO, three different nRF52840 module options. This is our
  primary reference for the power tree and MCU section. Open
  `ref-designguide-schematic/designguide-schematic.kicad_sch` in KiCad
  to view.

- **`lib/kleeb/`** — vendored MIT-licensed KiCad library from
  `crides/kleeb`. The only public source of the **MS88SF3 nRF52840
  module footprint + symbol** (in `lib/kleeb/mcu.pretty/ms88sf3.kicad_mod`
  and the `mcu.kicad_sym` symbol library). Add this to KiCad's path when
  drawing the schematic.

- **`lib/marbastlib/`** — CERN-OHL-P keyboard-focused KiCad library by
  ebastler. Used by zmk-designguide. Contains symbols + footprints for
  TP4056, XC6206, USB-C connectors, etc.

3D models from both libraries are stripped (~88 MB saved). Re-fetch the
original repos if you want 3D viewer support.

## Roadmap

In order (each step is its own commit on the `v1` branch):

1. **Start the KiCad project**: copy the designguide schematic as
   `thenar-v1-left.kicad_sch`, prune to the parts we want, add the
   MS88SF3 module section, add the MCP23017 expander section. Run ERC.

2. **Adapt for left vs right**: schematic-wise the halves are nearly
   identical; differ only in which is the BLE central (left) and the
   GPIO assignments. Two project files / one shared shematic + two
   variants — TBD.

3. **Generate a netlist** + import into a fresh PCB. Place footprints
   (Nice!Nano area, USB-C, I/O expanders) and let the matrix area
   come from a regenerated ergogen scaffold.

4. **Modify the ergogen config** for v1: drop reversibility, add
   `mirror: true` for the right half, swap switch-with-diode footprints
   for switch-only (since I/O expanders eliminate diodes).

5. **Route the board** (probably mostly by hand again — autoroute on
   v1 will hit similar plateaus as rc1).

6. **Generate gerbers + pick-place + BOM CSV** for JLCPCB submission.

## License notes

This v1/ directory bundles work under three licenses that are
compatible with this project's MIT licence:

- `ref-designguide-schematic/` — CERN-OHL-P v2 (`ebastler/zmk-designguide`)
- `lib/kleeb/` — MIT (`crides/kleeb`)
- `lib/marbastlib/` — CERN-OHL-P v2 (`ebastler/marbastlib`)

Both CERN-OHL-P and MIT permit redistribution + modification. Attribution
preserved by keeping each library's original LICENSE file untouched.
