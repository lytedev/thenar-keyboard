# Battery & power

How the thenar is powered, why v1 reports **0% battery** and won't
charge over USB, how to rework a v1 board, and what v2 must change.

## The v1 problem, in one sentence

The battery is wired to the nice!nano's **RAW** pin, but the nice!nano
v2's charger *and* its battery-voltage sense both live on the **B+**
pad — so v1 reports a flat 0% and USB does not charge the LiPo.

## How the nice!nano v2 power path actually works

- **B+ / B-** (underside pads): the battery connects here. B+ feeds
  **two** things — the onboard charge IC (charges the cell from USB 5 V)
  and the nRF52840's **VDDH**, which is the pin ZMK measures for battery
  level (high-voltage mode, battery voltage read via an internal
  divider).
- **RAW**: a *separate* 5 V/external supply input that feeds only the
  onboard 3.3 V regulator. RAW is **not** charged, and **not** sensed.

So a cell on RAW powers the board fine (the regulator makes 3.3 V) but
is invisible to both the charger and the battery gauge.

## What v1 actually does

`thenar/ergogen/config.yaml` wires:

```yaml
battery: { RAW: switch_from }          # battery+  -> switch_from net
slider:  { from: switch_from, to: RAW } # switch_from -> slider -> RAW pin
```

i.e. **battery+ → slider → RAW**. The nice!nano's B+/B- pads are left
unconnected. Result on v1 hardware:

- **Battery level reads ~0%**, always — VDDH/B+ sits at ~0 V, so ZMK
  computes 0% regardless of the real charge. The firmware is fine; it's
  measuring a pin the battery isn't on. (Verify with a multimeter: B+ to
  GND ≈ 0 V, RAW to GND ≈ cell voltage.)
- **USB does not charge the LiPo** — the charger charges B+, which has
  no cell. Plugging in USB powers the board but leaves the battery to
  drain with no top-up. Charge the cell externally until reworked.

This isn't a firmware bug and there's no firmware fix: ZMK reads the
board's built-in VDDH sensor, and you can't point it at RAW.

### Why it was wired this way

The footprint forced it. `thenar/ergogen/footprints/mcu_nice_nano.js`
(ceoloide's edge-pin footprint) exposes only the castellated pins —
`RAW / GND / VCC / RST / Pxx` — and **no B+/B- pads**. RAW was the only
power-input pad available, and routing the slider into it gave the clean
hardware cutoff the [spill-protection](spill-protection.md) guide relies
on. The cost of that convenience — no sensing, no charging — wasn't
obvious until first battery bring-up.

## v1 rework (what to do with a board you already have)

Solder the LiPo **directly to the nice!nano module's B+ and B- pads**
(underside, near the USB end), and take it **off** the PCB's
JST/slider/RAW path (don't leave it on both — B+ and RAW energised
together is a conflict). Then:

- ✅ battery level reads correctly (B+ → VDDH)
- ✅ USB charges the cell (charger → B+)
- ⚠️ the **slider stops doing anything** — it's in the now-unused RAW
  path. Rely on ZMK deep-sleep / soft-off for "off." Charging and a real
  battery gauge are worth more than a physical switch.

Tack the wires on before final seating if the module is socketed —
B+/B- are awkward to reach once it's down on the PCB.

## v2 fix (next PCB spin)

Add dedicated **B+/B- pads** to the board (either a footprint that
includes the nice!nano underside battery pads, or standalone pads the
user bridges to the module), then route **battery → slider → B+** — the
same shape the hypothenar already uses correctly:

```
hypothenar:  battery+ -> slider(VBAT_SW) -> VBAT -> {TP4056 BAT, MCU VDDH, sense divider}
thenar v2:   battery+ -> slider          -> B+   -> {nice!nano charger, VDDH sense}
```

With the slider in the battery→B+ path you keep the hardware cutoff
**and** get sensing + charging (charging happens with the slider **ON**;
slider off isolates the cell, as on the hypothenar). Fold this in with
the other v2 items tracked in `thenar/scripts/case.scad` (battery
pocket, screw-boss standoffs).

## The hypothenar does NOT have this problem

The hypothenar is a from-scratch power design (MS88SF3 module, own
TP4056 + LDO + sense divider). It routes **everything to one `VBAT`
net** — the cell (via the slider), the TP4056's BAT pin, the MS88SF3's
VDDH input, and a dedicated GPIO-switched ADC divider all share it — so
the charger charges the real cell and the divider measures the real
cell. See `hypothenar-keyboard/docs/power-budget.md`. The only bring-up
check: confirm the divider's high side is on `VBAT` (post-slider).

## Firmware note

Battery reporting stays **enabled** (ZMK default on the nice!nano v2) —
it is correct the moment a v1 board is reworked to B+/B-. Until then it
advertises a misleading 0% to the host; if that bothers you before you
rework, `CONFIG_ZMK_BATTERY_REPORTING=n` in `config/thenar.conf`
silences it, but the better path is the rework.
