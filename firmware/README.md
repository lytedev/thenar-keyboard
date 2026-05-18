# Thenar ZMK module

This is a ZMK shield module for the Thenar keyboard. It defines the
hardware (matrix, encoder, display) but not personal keymaps — users
fork this into a separate ZMK config repo and write their own keymap.

## Using this module

In your ZMK config repo's `config/west.yml`, add this module as a
remote-fetched dependency:

```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: lytedev
      url-base: https://github.com/lytedev
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: main
      import: app/west.yml
    - name: thenar-keyboard
      remote: lytedev
      revision: main
  self:
    path: config
```

Then in your `build.yaml`:

```yaml
include:
  - board: nice_nano_v2
    shield: thenar_left
  - board: nice_nano_v2
    shield: thenar_right
```

## Files in this module

- `zephyr/module.yml` — module manifest (tells west this is a ZMK module)
- `boards/shields/thenar/`
  - `Kconfig.shield` / `Kconfig.defconfig` — Kconfig entries for the shield
  - `thenar.dtsi` — matrix transform, encoder, sensor declarations
  - `thenar-layouts.dtsi` — physical key positions for ZMK Studio
  - `thenar_left.overlay` / `thenar_right.overlay` — per-half GPIO and SPI wiring
  - `thenar.keymap` — minimal default keymap (most users override this)

## Hardware specifics

- **Matrix**: 5x12 (5 scan rows × 12 columns = 6 per half with col-offset=6 on right)
- **Diode direction**: col2row (cathode to scanned row)
- **Encoder (EVQWGD001 scrollwheel)**: `alps,ec11` compatible. Left half
  uses Nice!Nano P20/P21, right uses P2/P3.
- **Display (Nice!View)**: SPI0; left CS=P4, right CS=P19.
- **Default keymap**: minimal QWERTY + BT layer. Override in your config repo.

## TODO before this firmware is ready to actually run

- Verify the matrix transform against a built keyboard. Some matrix
  coords were derived from the ergogen config and could be off by one
  on the mod row. Press every key after flashing and check ZMK's matrix
  scan output to confirm.
- Refine `thenar-layouts.dtsi` physical coords to match the actual PCB
  outline. The current values are placeholder approximations.
- Add a `thenar.zmk.yml` once the keyboard layout is locked in (ZMK
  Studio metadata).
- Consider adding RGB or PMW3360 trackball params if you're going to
  customise further; the upstream corax shield is a good reference.
