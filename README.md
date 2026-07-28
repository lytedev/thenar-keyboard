# Thenar

A column-staggered, fully-wireless split keyboard with scrollwheels — 56 keys (28 per half + thumb cluster). Choc-spaced, hotswap, Nice!Nano + ZMK.

## Repositories

- **Primary**: <https://git.lyte.dev/lytedev/thenar-keyboard>
- **Mirror (GitHub)**: <https://github.com/lytedev/thenar-keyboard>
- **Sibling model**: [hypothenar](https://git.lyte.dev/lytedev/hypothenar-keyboard) — the pick-and-place (JLCPCB PCBA) sibling: same layout, completely different electronics ([GitHub mirror](https://github.com/lytedev/hypothenar-keyboard))


- Choc-spaced, hot-swappable
- Scrollwheel (`EVQWGD001`) on both sides
- Strong pinky stagger (0.66) and a 5 deg. pinky splay
- Fully wireless built for Nice!Nano + ZMK (no TRRS jack)
- Nice!View support (5 pin connector)
- Reversible PCB
- 3d printable magnetic case, switchplate and MCU cover

## Gallery

TODO: Take photos of the assembled Thenar and add them here.

## Firmware

Natively supports [ZMK](https://zmk.dev/). Build + flash via the flake:

```sh
nix build .#firmware             # both halves
nix run .#flash -- left          # build + flash (double-tap reset when prompted)
nix run .#flash -- right
```

The shield definition + keymap live in [`config/`](./config/).
See `config/README.md` for the full firmware development workflow,
including hash-pinning the Zephyr SDK on first build.

## Build guide

[see the docs](./docs/) — [build](./docs/build.md), [routing](./docs/routing.md). Both are LLM-drafted and unverified; treat them as starting points until someone has built and routed a Thenar end-to-end.

## Development

The build has two phases:

1. **Ergogen produces a scaffold** — KiCad PCBs with all the footprints
   placed and nets assigned, but **no copper routing**. This is the
   starting point.
2. **A human routes the scaffold in KiCad by hand** and commits the
   result to `thenar/routed/`. Gerbers are then exported from the
   committed routed file, not from the ergogen scaffold.

This is unavoidable: ergogen is a layout generator, not an autorouter, and
a useful keyboard PCB needs every net wired up by hand to fit two layers.

### Flake packages

```sh
nix build .#scaffold          # ergogen -> KiCad PCBs (UNROUTED, for hand-routing)
nix build .#gerbers           # gerbers from thenar/routed/keyboard.kicad_pcb
nix build .#gerbers-zip       # ^^ zipped, ready to upload to JLCPCB etc. (default)
nix build .#switchplate-step  # STEP model of the switchplate (1.2mm)
nix flake check               # verifies thenar/routed/ placement matches scaffold
```

Each `result` symlink points at the artifact in `/nix/store`. For an
interactive shell with `ergogen`, `kicad-cli`, and `zip` available:

```sh
nix develop
```

### The two paths to fab-ready gerbers

- **Use the committed routed PCB.** `nix build .#gerbers-zip` and upload
  the result. This is the default path and the only one that has a chance
  of working without you doing any routing yourself.
- **Route your own.** Run `nix build .#scaffold`, open
  `result/pcbs/keyboard.kicad_pcb` in KiCad, route every net, save the
  routed file over `thenar/routed/keyboard.kicad_pcb`, then
  `nix build .#gerbers-zip`. If you fork the repo, commit your routed
  PCB so anyone using your fork gets it for free.

`nix flake check` runs `check-routing-drift`, which compares footprint
placement between the freshly-generated scaffold and the committed
`thenar/routed/` PCB. If you edit `thenar/ergogen/config.yaml` without
re-merging into the routed file, this check will fail loudly.

## License

MIT — see [LICENSE](LICENSE).
