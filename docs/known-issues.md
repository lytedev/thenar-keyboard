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

### Right half assembled with all 28 diodes reversed (assembly pitfall — the silk is correct)

**Symptom**: On the right half (the same reversible PCB flipped over,
components populated on the back face), every key is dead — zero keys
scan — while the encoder works fine. Cause: all 28 diodes were
installed reversed. The initial diagnosis blamed the footprint
(`diode.js` draws B.SilkS at the same coordinates as F.SilkS, so the
back arrow *looks* reversed compared to the front render), but that
turned out to be wrong: a mirrored view flips the pads together with
the silk, so the cathode bar stays adjacent to the same pad/net on
both faces. Identical-coordinate back silk is exactly what upstream
ergogen and ceoloide's footprint library ship, and it indicates the
correct polarity when read from the back.

**Where**: Not in the codebase — it's an assembly-process trap. On a
flipped board the *correct* diode orientation looks mirrored relative
to the other half. Orienting the back-face diodes by visual match
(making the arrows/bands point the same way as the working left half,
or as a front-view render) reverses every one of them.

**Current workaround**: On the already-built right half, rotate all 28
diodes 180°. When assembling a back face, orient by **bar-to-pad
adjacency** — the component's cathode band goes at the end where the
silk bar sits, next to whichever pad that is — never by remembered
arrow direction. Correctly built halves LOOK mirrored to each other.

**Verification (5-second test)**: Flip the working left half over. Its
bare back face shows the B.SilkS arrows beside diodes whose bands are
known good; the back-silk bar sits at the same end as each working
diode's band, proving the back silk indicates correct polarity.

**Hardening (in tree)**: `thenar/ergogen/footprints/diode.js` now adds
a small "K" cathode letter next to the bar on both faces (the B.SilkS
copy is `justify mirror`ed so it reads as a proper K from the back).
Future fabs get an unambiguous letter instead of geometry alone;
already-fabbed v1.0 PCBs don't have the K, so use the adjacency rule
above.

---

(Add new deviations above this line as they're found.)
