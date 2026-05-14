# Routed PCB

This directory holds the **manually-routed** KiCad PCBs that gerbers are built
from. Ergogen places footprints and assigns nets, but does not route copper —
that step has to be done by hand in KiCad. The result of that hand-routing
lives here and is committed.

## Workflow

1. `nix build .#pcbs` produces the ergogen scaffold (footprints + nets, no
   traces) at `result/pcbs/keyboard.kicad_pcb`.
2. The first time, that scaffold is copied verbatim into this directory as a
   seed. You then open it in KiCad and route the traces by hand. Commit the
   routed file.
3. `nix build .#gerbers` reads the routed file *from here* — not from the
   ergogen output — and produces fabricatable gerbers.
4. If you edit `thenar/ergogen/config.yaml` (e.g. moving a key, adding a
   footprint), the ergogen scaffold and this routed file go out of sync.
   Run `nix flake check` (or `nix build .#check-routing-drift`) to catch
   that — it compares footprint placement between the freshly-generated
   scaffold and this committed PCB. When drift is detected, you need to
   merge the new footprint placement back into the routed PCB in KiCad
   (KiCad can do this incrementally via "Update PCB from Schematic" style
   workflows, but with ergogen the simplest path is usually: open the new
   scaffold, copy your routing over from the old routed file, and re-save).

## Current state

> **⚠️ Currently unrouted.** The files here are a verbatim copy of the
> ergogen output. They will produce empty/unusable gerbers until someone
> opens them in KiCad and routes the traces. Do **not** order PCBs from
> the current gerber output.
