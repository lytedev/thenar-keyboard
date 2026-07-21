# Thenar — outstanding work

Snapshot of everything left as of 2026-07. The keyboard **works today**
(both halves, both encoders, full keymap, wireless) — everything below
is improvement/rework, not "it's broken." Cross-refs point at the docs
that have the detail.

## Hardware rework — the rev1 board in hand

- [ ] **Move the LiPo from RAW → nice!nano B+/B-.** As-fabbed, the
      battery is on RAW, so it reads a flat **0%** and **USB won't charge
      it**. Solder the cell to the module's B+/B- pads (it sits in the gap
      under the socketed module), off the JST/slider/RAW path. Restores
      battery sensing + USB charging. → `docs/battery-and-power.md` (rev1
      rework). Charge the cell externally until this is done.
- [ ] **(Optional) Rewire the slider to P0 for soft-off** — if you want
      the switch back as an on/off (µA sleep, still charges). Otherwise
      the slider goes dead after the rework and idle deep-sleep covers
      "off". → same doc, "advanced" rework.

## rev2 PCB — for the next fab (ergogen source is already rev2)

- [ ] **Delta-patch `thenar/routed/keyboard.kicad_pcb` in KiCad.** The
      ergogen source is rev2 (battery→`BAT_BPLUS`, slider→`SOFT_OFF`/P0)
      but the routed board is still rev1, so the flake `routing-check` is
      **RED** until this lands. The delta is tiny — 4 pad-net reassigns +
      delete 2 traces + route 1 trace + silk + DRC. Exact recipe (net
      table) in `docs/battery-and-power.md` → "Reroute recipe (Path A)".
      Autoroute fallback = `nix build .#routed-auto`.
- [ ] After patching, commit the routed board → `routing-check` goes
      green → export gerbers → fab rev2 if/when you want new boards.

## Firmware

- [ ] **Apply the soft-off scaffold** (`CONFIG_ZMK_PM_SOFT_OFF` + the P0
      wakeup-GPIO node) once a board actually has the slider on P0, then
      bench-test soft-off + charge-while-off. Kept out of active firmware
      until testable. → `docs/battery-and-power.md` (rev2 firmware).

## Desktop integration (dragon / DankMaterialShell)

- [ ] **DMS `isLaptopBattery` patch** so the keyboard battery renders in
      the bar. `upower` already exposes the Thenar (PR #789 merged); DMS
      filters UPower devices to laptop batteries only, so peripherals are
      dropped. Patch `dotfiles/dms` to surface non-laptop batteries.
      Only meaningful after the B+/B- rework makes it report a real %.

## Leisure / finishing

- [ ] Print the switch plate + case (STLs current; all cutouts fixed).
- [ ] Conformal-coat for spill resistance → `docs/spill-protection.md`
      (mask list included). Do it *after* the battery rework — it's a
      finishing step, not a bring-up one.

## Done (for reference — no action)

Encoder (both rotation + press), the full Iris + Miryoku keymap,
Config-gated Miryoku entry, reliable Lower+Config→Nav tri-layer, +8 dBm
TX power for wireless latency, bootloader-recovery flashing — all landed
and committed on `main`. rev1 is frozen at tag `hw-rev1`.
