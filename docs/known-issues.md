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

---

(Add new deviations above this line as they're found.)
