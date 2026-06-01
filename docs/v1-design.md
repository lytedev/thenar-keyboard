# Thenar v1 design notes

This branch (`v1`) is a redesign of the prototype (rc1, on `main`) for
**pick-and-place assembly via JLCPCB**. The user-visible changes:

- **No Nice!Nano module** — discrete nRF52840 chip on the main PCB.
- **No diodes** — 2× MCP23017 I²C I/O expanders per half, switch-per-pin
  topology (each key wired directly to one expander GPIO).
- **Most components placed by JLCPCB PCBA**, only through-hole / mechanical
  parts (switches, hotswaps, encoder, slider, reset, battery wires)
  hand-soldered.

rc1 (current `main`) stays as the validated prototype reference.

## Architecture choices

### MCU: nRF52840 (bare chip)

- LCSC part: `C840628` (Nordic, available, "Basic" tier on JLCPCB)
- Same chip the Nice!Nano uses; ZMK upstream supports it.
- Needs: 32 MHz crystal + 2× 12 pF caps, 32.768 kHz crystal + caps,
  decoupling network (5× 100 nF + 1× 4.7 µF), DCDC inductors per
  Nordic reference design.

### Antenna: chip antenna

- Recommended: **Johanson `2450AT18B100E`** (2.45 GHz chip antenna,
  surface-mount).
- LCSC: `C503520` (verify before order).
- Layout: requires only a short trace from the nRF52840 ANT pin and a
  ground keep-out under the antenna. Much more forgiving than PCB
  trace antennas; trades ~$0.30/board for "it just works."

### I/O expanders: 2× MCP23017 per half

- LCSC: `C9678` (Basic part). 16 GPIOs each, 32 total per half, 28 used
  for keys + 4 spare.
- I²C address strap: 3 address pins → 8 possible addresses per bus.
  Use 2 different addresses for the 2 expanders. Both halves use the
  same addressing since the MCU is local to each half.
- Pull-up resistors: 4.7 kΩ on SDA/SCL.
- Reset: tie `RESET` to MCU GPIO so MCU can reset the expanders on
  boot.

### USB-C: standard 24-pin receptacle

- LCSC: `C165948` (Korean Hroparts; common JLC-stocked USB-C).
- ESD protection: USBLC6-2SC6 (`C7519`) for D+/D-.
- 5.1 kΩ resistors on CC1/CC2 for USB-C pull-down (signals "I'm a UFP
  needing power").

### Power path

- **Battery in**: LiPo 3.7V nominal, same `301230` as rc1.
- **Charge IC**: MCP73831 (LCSC `C424093`) — 500 mA charge, single-cell.
- **Regulation**: Nordic nRF52840 can run directly from LiPo voltage
  via its built-in DCDC (1.7–5.5 V input range). No boost/buck needed
  for the MCU itself.
- **3.3V rail** for MCP23017 + Nice!View: TLV70233 LDO (`C144586`)
  fed from battery. Tiny load (few mA peak) so a small LDO is fine.
- **Slider switch**: Same C128955 cuts the battery feed to charge+MCU.
- **Charge LED**: optional, 1× 0603 LED + 1 kΩ resistor wired to
  MCP73831's STAT pin.

### SWD programming header

- **5 pads** on the down-side near the MCU: SWDIO, SWCLK, RST, GND, 3V3.
- 2.54 mm spacing in a single row, exposed copper (no header pins
  installed by default — clip-on or pogo probe).
- Used once per board to flash the Adafruit nRF52 bootloader. After
  that, USB drag-drop works exactly like the Nice!Nano.

### Bootloader flashing strategy

Recommended programmer: **Pi Pico flashed as `picoprobe`** (~$5,
DAPLink-compatible). Then OpenOCD command:

```
openocd -f interface/cmsis-dap.cfg -f target/nrf52.cfg \
  -c "program adafruit_nrf52_bootloader.hex verify reset exit"
```

Adafruit bootloader hex from <https://github.com/adafruit/Adafruit_nRF52_Bootloader>
(use the `feather_nrf52840_express` build or `nice_nano_v2` build).

## ZMK shield changes

The shield needs a custom board definition (`nice_nano` board no longer
applies). Path: create `config/boards/arm/thenar_v1/` as a custom Zephyr
board, then the shield references it. Includes:

- `thenar_v1.dts` — MCU + power + connectivity (chosen flash partitions,
  USB, I²C, BLE)
- `thenar_v1_defconfig` — Kconfig for the board
- `Kconfig.board` — board declaration
- `board.cmake` — flash/debug command wiring

The kscan changes from `kscan-gpio-matrix` to **`zmk,kscan-gpio-direct`**
with all 28 GPIOs listed explicitly (each one is a switch).

The I/O expanders need a Zephyr driver — `MCP230XX` (built into Zephyr).
Devicetree binding: declare each as an `i2c-bus` device, configure pin
modes via the driver. Then `gpio-keys` or `kscan-gpio-direct` references
the expander's GPIO controller via phandles.

## BOM at LCSC (PCBA-ready)

Per half (multiply ×2 for the keyboard total):

| Part | Designator | LCSC | Tier | Notes |
|---|---|---|---|---|
| nRF52840 QIAA | U1 | C840628 | Basic | The MCU |
| Chip antenna 2.45 GHz | E1 | C503520 | Extended? | Johanson 2450AT18B100E |
| MCP23017 | U2, U3 | C9678 | Basic | I/O expanders ×2 |
| MCP73831 | U4 | C424093 | Basic | LiPo charge IC |
| TLV70233 | U5 | C144586 | Basic | 3.3V LDO |
| USBLC6-2SC6 | U6 | C7519 | Basic | USB ESD protection |
| USB-C receptacle (24-pin) | J1 | C165948 | Basic | Hroparts TYPE-C-31-M-12 |
| 32 MHz crystal, 9 pF load | Y1 | C32346 | Basic | NDK NX2016SA |
| 32.768 kHz crystal | Y2 | C32346 | Basic | (verify) |
| 22 pF 0603 | C1–C4 | C1653 | Basic | Crystal load caps ×4 |
| 4.7 µF 0603 | C5 | C19666 | Basic | Bulk decoupling |
| 100 nF 0603 | C6–C15 | C14663 | Basic | Local decoupling ×10 |
| 10 µH 0603 inductor | L1, L2 | C1046 | Basic | DCDC ×2 |
| 4.7 kΩ 0603 | R1, R2 | C23162 | Basic | I²C pull-ups |
| 5.1 kΩ 0603 | R3, R4 | C23186 | Basic | USB-C CC pull-downs |
| 1 kΩ 0603 | R5–R7 | C21190 | Basic | Various pull-ups |
| 100 kΩ 0603 | R8, R9 | C25803 | Basic | Reset pull-ups |
| LED 0603 (status) | D1 | C84256 | Basic | Optional |

Manual / through-hole:
- 28× Kailh Choc hotswap sockets (C2913963)
- 1× EVQWGD001 encoder
- 1× C128955 slider switch
- 1× 2-pin tactile reset
- 1× 5-pin Nice!View header (if displaying)
- 2× battery solder pads

Same switches + keycaps + LiPo battery as rc1 (no change there).

**Rough cost per half**: ~$12-15 in components from LCSC + ~$25-40 for
JLCPCB PCBA setup (depending on Basic/Extended part mix). So ~$70-110
for both halves' boards-with-chips-on, plus the through-hole BOM
(switches/keycaps still $50-80 total).

## Layout/routing risks (in roughly increasing order of risk)

1. **Power decoupling placement** — well-known recipe in the nRF52840
   datasheet. Follow Nordic's reference layout.
2. **I²C bus routing** — keep traces short, 4.7 kΩ pull-ups, both
   expanders on same bus is fine.
3. **USB-C signal integrity** — D+/D- should be ~90 Ω differential. At
   USB 2.0 speeds and our short trace lengths it's forgiving.
4. **32 MHz crystal layout** — Nordic has strict guidelines (ground
   guard ring, exact load caps). Get this wrong and BLE may not start.
5. **2.45 GHz antenna match** — even with a chip antenna, the feed
   trace needs a ground-keepout zone of ~5×8 mm. Get this wrong and
   range/reliability suffers.
6. **DCDC inductor layout** — physically close to nRF52840's DCC pins
   with a short ground return.

## Roadmap

- [ ] Architectural spike: confirm I²C-based I/O expanders work with ZMK
      via `MCP230XX` driver (research existing builds).
- [ ] Schematic in KiCad (NOT ergogen — ergogen doesn't do schematics,
      and we need one for proper review).
- [ ] Footprint set: vet ceoloide / infused-kim libraries; supplement
      with custom footprints where needed.
- [ ] Ergogen config that emits the matrix layout + key positions, then
      manually overlay the chip / power / USB area in KiCad on top of
      the ergogen scaffold.
- [ ] First-pass PCB layout in KiCad. Order of design: place MCU + RF
      first, then power, then I²C bus, then key matrix wiring.
- [ ] Pick-place + BOM files via `kicad-cli pcb export pos --format csv`
      and `kicad-cli sch export bom`.
- [ ] Test PCBA order: 5 boards, 1 fully assembled, 4 bare for spares /
      iteration.

## Reference designs

- **ZackFreedman/MiRage** — split, custom PCB, nRF52840, PCBA-assembled
- **urob/zmk-sweep** — chip-direct ergogen layout
- **Nordic reference designs** — official PCB reference for nRF52840
  (`nRF52840 DK` schematic is public; that's the authoritative reference)
- **Adafruit Feather nRF52840 Express** schematic — known-good
  bare-chip reference layout
