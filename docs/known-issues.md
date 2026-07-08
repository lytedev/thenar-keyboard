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

### Right half "all 28 diodes reversed" was a misdiagnosis — the diodes AND the silk were correct; the old right-half firmware scanned backwards

**Symptom (as observed at the time)**: On the right half (the same
reversible PCB flipped over), every key was dead — zero keys scanned —
while the encoder worked fine. A bench experiment then appeared to
convict the diodes: a diode installed with its band *opposite* the
soldering face's silk scanned, while diodes following the silk did not
conduct "in the scan direction". Two sessions of analysis flip-flopped
between "the back silk is unmirrored and therefore wrong" and "the silk
is correct, the assembly is reversed" (the previous version of this
entry). **Both causal stories were wrong.**

**What was actually broken**: the pre-`fdf3b3df`
`thenar_right.overlay` had the kscan pin roles swapped. Per the ZMK
driver source (`kscan_gpio_matrix.c`: for `diode-direction = "col2row"`
the macro `COND_DIODE_DIR` makes `.inputs = row-gpios` and
`.outputs = col-gpios` — i.e. **row-gpios are SENSED, col-gpios are
DRIVEN**, which is also why stock shields like the corne put the
pull-downs on row-gpios), the old right overlay *drove* pins 9/8/7/6/5/4
(nets col4..col0 plus the display CS line) and *sensed* pins
18/15/14/16/10 (nets row1..row5). That is exactly backwards from the
board's diode direction, so:

- every correctly-installed diode blocked the (reversed) scan current →
  zero keys, encoder unaffected;
- the one diode deliberately flipped during debugging conducted in that
  reversed direction → "band opposite the silk works", the observation
  that spawned the reversed-diodes myth.

A contributing confusion that survives in the overlay comment blocks:
they label row-gpios as "driven outputs" and col-gpios as "sensed
inputs". **Those comments are backwards** relative to the driver (fix
pending — out of scope for the change that corrected this entry).

**What the silk actually indicates**: the correct cathode end, on
**both** faces, including already-fabbed v1.0 boards. Derivation from
the generated netlist: diode pad 1 (x=-1.65, present on F.Cu and B.Cu)
carries the `to`/row_net (col0..col4 — the nets on MCU pins 5-9, the
sensed row-gpios); pad 2 carries the per-key `colrow` net to the
switch and on to the driven row0..row5 nets. Scan current runs
driven rowN → switch → colrow → diode → sensed colN, so the cathode
belongs at pad 1 — and the silk bar (x=-0.35) sits adjacent to pad 1
on both F.SilkS and B.SilkS. Renders of the front face and the
mirrored back face both show the arrow pointing at, and the bar/K
marking, the pad-1/colN end. No face of any fab has misleading silk.

**The rule (one sentence)**: On either face of the board, solder every
matrix diode with its cathode band at the end marked by that face's
silk bar / arrow tip (the end labeled "K" on post-v1.0 fabs) — the pad
wired to a col0..col4 net — and never orient by comparing against the
other half or a front-view render (correctly built halves LOOK
mirrored to each other).

**Current state / workaround**: none needed for assembly — follow the
silk. Do **not** apply this entry's previous workaround ("rotate all
28 right-half diodes 180°"): the installed diodes were never reversed
(the post-fix firmware types through them, which is only electrically
possible with bands at the bar end), and rotating them would kill
every key. If the single band-opposite test diode from the bring-up
experiment is still installed, flip it back to match the silk — its
key is dead under the corrected firmware.

**Hardening (in tree)**: `thenar/ergogen/footprints/diode.js` adds a
small "K" cathode letter next to the bar on both faces (the B.SilkS
copy is `justify mirror`ed so it reads as a proper K from the back),
and now carries the full polarity derivation in a comment. v1.0 PCBs
predate the K; use the bar/arrow-tip rule above.

---

(Add new deviations above this line as they're found.)
