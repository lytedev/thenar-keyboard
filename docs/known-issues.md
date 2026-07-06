# Known issues / deviations

Things found during actual builds that should be fixed in a future PCB
revision. Each entry lists what bit, where it lives in the codebase, and
the workaround for the current revision.

## v1.0 — present rev

### Scrollwheel mounting peg has no hole

**Symptom**: The Panasonic EVQWGD001 encoder has a small plastic
alignment peg on its underside (in addition to the 6 electrical pins).
The current footprint provides through-holes for the pins and an
Edge.Cuts slot for the encoder body — but **no NPTH for the plastic
peg**. Builders have to trim the peg off with flush cutters before the
encoder will sit flush.

**Where**: `thenar/ergogen/footprints/scrollwheel_mirrored.js` — the
`pins(...)` function adds the electrical THT pads and Edge.Cuts but
doesn't add an NPTH for the peg.

**Current workaround**: Trim the peg before placing the encoder. The
build guide (`docs/build.md`, "Scrollwheel" section) already mentions
this as "cut off the foot on the left side of the encoder."

**v2 fix**: Add an `np_thru_hole` at the peg's coordinate (need to
measure on a real encoder; the EVQWGD001 datasheet lists mechanical
dimensions but the peg location isn't always shown). Size around
1.2 mm diameter should be enough.

### Screw holes are plated and one merges with the 5-key pad

**Symptom**: The inner-num key ("5" on the left half) doesn't register.
The top-right screw hole is a *plated* through-hole (PTH) whose copper
annulus physically touches the switch's down-side hotswap pad (DRC:
`PTH pad [<no net>] of _5` vs `Pad 2 [inner_num] of S26`). Two failure
modes: (1) the huge copper ring acts as a heat sink fused to the pad,
so the hotswap socket joint goes cold during soldering — this is what
actually bit; (2) a metal screw + standoff chain through that hole can
ground the switch net.

**Where**: `thenar/ergogen/footprints/hole.js` emits a plated pad; the
`screw_top_right` zone anchor in `thenar/ergogen/config.yaml` places it
too close to `matrix_inner_num`.

**Current workaround**: Solder that hotswap socket with extra heat and
dwell time (the ring steals heat). Prefer a nylon screw or washer at
that position.

**v2 fix**: Make the hole footprint NPTH (no copper), and/or move the
`screw_top_right` anchor a couple mm away from the key. The same `hole.js` wrapper was copied into the hypothenar repo
(github.com/lytedev/hypothenar-keyboard) — fix it there too.

### EVQWGD001 rotation needs CONFIG_EC11 (fixed, kept for the record)

**Symptom**: Encoder press works but rotation does nothing, with
perfect continuity on all three signal legs. The `alps,ec11`
devicetree nodes alone do NOT pull in the driver — without
`CONFIG_EC11=y` the firmware builds cleanly and rotation is silently
dead.

**Fix (in tree)**: `config/thenar.conf` sets `CONFIG_EC11=y` and
`CONFIG_EC11_TRIGGER_GLOBAL_THREAD=y`. If rotation ever dies again
after config surgery, first check that file still exists and that the
build log contains `ZMK Config Kconfig: .../config/thenar.conf` and
`ec11.c.obj`.

---

(Add new deviations above this line as they're found.)
