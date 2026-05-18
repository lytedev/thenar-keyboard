# Thenar ZMK config / shield

The Thenar ZMK shield module + a build setup so `nix build .#firmware`
and `nix run .#flash -- (left|right)` work locally without GitHub
Actions.

## Building + flashing

```sh
# Build both halves -> a derivation containing zmk_left.uf2 + zmk_right.uf2.
nix build .#firmware

# Or just one half (each produces a .uf2 directly):
nix build .#firmware-left
nix build .#firmware-right

# Flash one half. Double-tap reset on the Nice!Nano when prompted.
nix run .#flash -- left
nix run .#flash -- right
```

The first build will fail with a `zephyrDepsHash` mismatch — paste the
hash nix reports into `flake.nix` (`zephyrDepsHash = ...`) and rebuild.
This hash pins the Zephyr SDK + west modules so subsequent builds are
hermetic.

## Files

- `west.yml` — west manifest. Pulls upstream ZMK and points west at this
  directory's `boards/` for shield discovery.
- `build.yaml` — ZMK CI matrix (for GitHub Actions / similar). Not used
  by the local nix build, but useful if you want to add CI later.
- `thenar.keymap` — the default keymap zmk-nix's `buildSplitKeyboard`
  picks up. Edit for personal tweaks.
- `boards/shields/thenar/`
  - `Kconfig.shield` / `Kconfig.defconfig` — Kconfig entries for the shield.
  - `thenar.dtsi` — matrix transform, encoder, sensor declarations.
  - `thenar-layouts.dtsi` — physical key positions (for ZMK Studio).
  - `thenar_left.overlay` / `thenar_right.overlay` — per-half GPIO + SPI.
  - `thenar.keymap` — fallback keymap built into the shield definition.

## Hardware specifics

- **Matrix**: 5×12 (5 scan rows × 12 columns; 6 per half with `col-offset=6` on right).
- **Diode direction**: `col2row`.
- **Encoder (EVQWGD001 scrollwheel)**: `alps,ec11` compatible. Left half
  uses Nice!Nano P20/P21, right uses P2/P3.
- **Display (Nice!View)**: SPI0; left CS=P4, right CS=P19.

## Forking for a personal keymap

Easiest path: clone this repo, edit `config/thenar.keymap`, build with
`nix build .#firmware-left` / `nix build .#firmware-right`. Your keymap
edits stay in your fork.

For the "proper" ZMK ecosystem flow (separate config repo that pulls in
the shield as a remote module), point your `config/west.yml` at this
repo's `config/boards/` directory and define `shield: thenar_left` /
`thenar_right` in your build matrix.

## TODO before the firmware is fully verified

- **Matrix transform verification**: the mod-row matrix coords (`RC(4,1..4)`
  and `RC(4,7..10)`) were derived from `thenar/ergogen/config.yaml`'s
  `column_net`/`row_net` overrides. Could be off by one in the mod row.
  Press every key after flashing and check ZMK's matrix scan output.
- **Physical layout refinement**: `thenar-layouts.dtsi` coords are
  placeholder approximations of the corax layout adjusted for our
  extra outer-num key. Real values come from a built keyboard.
- **`thenar.zmk.yml`**: ZMK Studio metadata, add once the layout's stable.
