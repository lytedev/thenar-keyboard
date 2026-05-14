# Thenar

A column-staggered, fully-wireless split keyboard with scrollwheels — 56 keys (28 per half + thumb cluster). Choc-spaced, hotswap, Nice!Nano + ZMK.

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

Natively supports [ZMK](https://zmk.dev/).

TODO: Fork/create a ZMK config + module for the Thenar layout. The old Corax
ZMK module does not cover the extra num-row key on the outermost column.

## Build guide

[see here](./docs/BuildGuide.md) (TODO: stub — needs to be written for Thenar).

## Development

Everything builds through Nix flake packages. From the repo root:

```sh
nix build .#pcbs              # ergogen -> KiCad PCBs + DXF outlines
nix build .#gerbers           # kicad-cli -> gerber + drill files
nix build .#gerbers-zip       # zipped gerbers for fab houses (e.g. JLCPCB)
nix build .#switchplate-step  # STEP model of the switchplate (1.2mm)
```

Each `result` symlink points at the artifact in `/nix/store`. For an interactive
shell with `ergogen`, `kicad-cli`, and `zip` available:

```sh
nix develop
```

## License

MIT — see [LICENSE](LICENSE).
