# Thenar v1 firmware

ZMK firmware for the v1 PCBA build (MS88SF3 module + 2× MCP23017 per
half over I²C, switch-per-pin, no diodes).

## Status: skeleton

This is a starting point that compiles in principle, NOT a verified
working firmware. Several pin assignments are placeholders that must
be reconciled against the final PCB:

- **MS88SF3 pad-to-nRF52840 GPIO map** — confirm against the Minew
  datasheet, then update both `thenar_v1-pinctrl.dtsi` AND
  `v1/ergogen/config.yaml` together so wiring matches the firmware.
- **I²C addresses** — `mcp_a` at `0x20`, `mcp_b` at `0x21` matches
  the address-strap wiring in the ergogen config. If you change those,
  update `thenar_v1.dts`.
- **Battery voltage divider GPIO** — `vbatt` references `&gpio0 13`;
  the actual divider pin depends on which MS88SF3 pad is used.

The first physical board will need a debug pass to verify all of the
above before this firmware works end-to-end.

## Layout

```
v1/zmk/
├── boards/arm/thenar_v1/        # Custom Zephyr board for MS88SF3
│   ├── board.cmake
│   ├── Kconfig.board
│   ├── Kconfig.defconfig
│   ├── thenar_v1.dts            # MCU + I²C + MCP23017 children
│   ├── thenar_v1-pinctrl.dtsi   # Pin selections
│   ├── thenar_v1.yaml           # Board metadata
│   └── thenar_v1_defconfig
├── boards/shields/thenar_v1/    # Keyboard shield
│   ├── Kconfig.shield
│   ├── Kconfig.defconfig
│   ├── thenar_v1.dtsi           # kscan + transform + encoder
│   ├── thenar_v1-layouts.dtsi   # Physical positions for Studio
│   ├── thenar_v1_left.overlay   # Left half input-gpios list
│   ├── thenar_v1_right.overlay  # Right half input-gpios list
│   └── thenar_v1.keymap         # Default keymap
├── build.yaml
└── west.yml
```

## Build

```bash
# All-in-one (firmware + flash helper):
nix build .#v1-firmware
nix run .#v1-flash -- left
nix run .#v1-flash -- right

# Or just one half:
nix build .#v1-firmware-left
nix build .#v1-firmware-right
```

The first build fetches Zephyr deps and fails with a hash mismatch.
Copy the hash from the failure message into `flake.nix` (the
`v1-firmware`'s `zephyrDepsHash`) and rebuild.

## Topology notes

Why switch-per-pin (no matrix, no diodes):

- 2× MCP23017 per half give 32 GPIOs; we use 28 of them.
- Each switch shorts a single MCP23017 pin to GND when pressed; the
  driver's internal pull-up keeps the line high otherwise.
- ZMK's `zmk,kscan-gpio-direct` driver polls the expanders over I²C.
- No charlieplexing, no row/column matrix, no diodes — simplest
  electrical topology, but the per-switch I/O cost is higher (32 pins
  vs ~12 for a traditional matrix).

Why this works on a battery-powered keyboard:

- MCP23017 quiescent current is ~1 µA, negligible vs the BLE radio.
- I²C bus is only polled when a switch state changes (interrupt-
  driven) — the MCP23017 INT pin can wake the MCU from sleep.

Caveat (future work): the current shield reads the expanders by
polling, not via the MCP23017's interrupt pin. For battery life that
matters; wire `INTA`/`INTB` of each expander to an MCU GPIO and add
an interrupt binding to the kscan node. See ZMK's docs on
`gpio-input-bind` for the pattern.

## ZMK Studio support

`thenar_v1-layouts.dtsi` defines the physical layout for ZMK Studio so
you get a keymap visualizer. Positions come from the rc1 layout (same
key geometry) — verify the v1 PCB outline hasn't drifted before you
trust the visualization.
