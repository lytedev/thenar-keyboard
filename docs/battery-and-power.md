# Battery & power

How the thenar is powered, and the clean split between **rev1 (rc1)** —
the boards already fabricated, which need a battery-wiring rework — and
**rev2** — the updated design that fixes it properly.

> **Revisions.** `git tag hw-rev1` freezes the as-fabricated rev1 PCB.
> `main` evolves into rev2 in place; recover rev1 files with
> `git show hw-rev1:thenar/routed/keyboard.kicad_pcb`.

## Background: how the nice!nano v2 power path works

One fact drives everything below: on the nice!nano v2 the **battery, the
onboard charger's output, and the MCU's supply are all the same node —
`B+` / VDDH**.

- **B+ / B-** (underside pads): the battery connects here. B+ feeds both
  the onboard charge IC (charges from USB 5 V) *and* the nRF52840's
  **VDDH**, which is the pin ZMK measures for battery level.
- **RAW**: a *separate* 5 V input that feeds only the 3.3 V regulator.
  RAW is **not** charged and **not** sensed.

So a cell on RAW powers the board but is invisible to both the charger
and the gauge. And because B+ = charger = MCU supply are one node, you
**cannot** hard-switch the MCU off while still charging the cell — those
are the same wire. "Off but charging" is only achievable *electronically*
(ZMK soft-off, ~µA), not with a mechanical cut. Both facts shape the
rev1 rework and the rev2 design.

---

## rev1 (rc1): the as-fabricated boards

### The problem

`thenar/ergogen/config.yaml` (at `hw-rev1`) wires **battery+ → slider →
the nice!nano RAW pin**; the B+/B- pads are unconnected. Consequences on
a board in hand:

- **Battery level reads a flat ~0%** — VDDH/B+ sits at ~0 V, so ZMK
  computes 0% regardless of real charge. (Multimeter check: B+ to GND ≈
  0 V, RAW to GND ≈ cell voltage.)
- **USB does not charge the LiPo** — the charger charges B+, which has no
  cell. USB powers the board but the battery only drains. Charge the cell
  externally until reworked.

Not a firmware bug — ZMK reads the board's built-in VDDH sensor and can't
be pointed at RAW. It's a wiring problem, forced by the footprint:
`mcu_nice_nano.js` exposes only the castellated edge pins (RAW/GND/VCC/
RST/Pxx) and **no B+/B- pads**, so RAW was the only power-input pad
available.

### The rework (existing boards)

The nice!nano is socketed on headers with the LiPo sitting in the gap
underneath it, so the module's underside B+/B- pads face the battery —
a short direct wire.

**Basic (working battery, ~5 min):**

1. Solder LiPo **+ → module B+**, **- → module B-** (B- is just GND).
2. Take the cell **off** the JST/slider/RAW path (don't leave it on both
   B+ and RAW — that's a conflict).
3. Result: correct battery %, USB charging works. The **slider is now
   dead** (it sat in the RAW path); "off" is ZMK's automatic deep-sleep.

**Advanced (also get the slider back as a soft-off switch):** additionally
rewire the slider off the power rail and onto spare GPIO **P0** (other
terminal to GND), and enable soft-off in firmware (see rev2 firmware
notes — the same config works on a reworked rev1 board). Then the slider
becomes a real on/off that still charges while off.

---

## rev2: updated power design

Goal the user asked for: **the slider turns the keyboard off, and it can
still charge while off.** Given the nice!nano constraint above, that means
**soft-off**, not a hard cut.

### Design

- **Battery → B+/B-.** The board gains labeled B+/B- solder pads (with
  silk "→ nice!nano B+/B-") in the battery cavity; the builder runs the
  short wire up to the module. Nothing routes to RAW. This restores
  sensing + USB charging by construction.
- **Slider → spare GPIO `P0`** (not the power rail). Wired as a ZMK
  **soft-off trigger + wake source**: slide off → System OFF (~5–15 µA);
  slide on → wake.
- **Charging is autonomous** — the onboard charger runs regardless of MCU
  state, so USB charges the cell whether awake or in soft-off. ✅

### What users get (matches commercial/premium wireless UX)

Plug in USB → it charges. OS shows a real battery %. Flip the slider →
stops typing, sleeps at µA. Flip back → wakes instantly, BT bond intact.
Charges in any switch position — like a Logitech/Apple keyboard, unlike
the common DIY hard-cut switch.

### The one tradeoff

Soft-off is ~µA, not a *true* zero-current disconnect — B+ stays lightly
energized. So it's slightly weaker than a hard battery cut for the
**spill** scenario. On a nice!nano you can't have both hard-disconnect
*and* charge-while-off; rev2 chooses charge-while-off. See
[spill-protection](spill-protection.md) — its "cut battery power" step is
now a soft-off, not a hard cut.

### Firmware (soft-off)

rev2 (and advanced-reworked rev1) needs ZMK soft-off enabled and the P0
slider configured as a soft-off trigger + wake source. Battery reporting
stays enabled — it's correct the moment a board has the cell on B+/B-.

Kept **out of the active firmware** deliberately: it can't be validated
until a board actually has the slider on P0, and the exact soft-off DT is
ZMK-version-specific. Apply this once you've reworked/built a rev2 board,
then bench-test. Reference: <https://zmk.dev/docs/features/soft-off>.

`config/thenar.conf`:

```
CONFIG_ZMK_PM_SOFT_OFF=y
```

Shield overlay — scaffold (validate against ZMK v0.3.0's soft-off API and
**confirm the P0 → &pro_micro/&gpio index** against the nice!nano pinout
before flashing):

```dts
/ {
    soft_off_key: soft_off_key {
        compatible = "gpio-keys";
        key {
            // P0 slider -> GND (ACTIVE_LOW). Map <PIN> to the nice!nano
            // P0 pad's actual GPIO - do NOT assume; check the pinout.
            gpios = <&pro_micro PIN (GPIO_ACTIVE_LOW | GPIO_PULL_UP)>;
        };
    };
    soft_off_scan: soft_off_scan {
        compatible = "zmk,kscan-gpio-direct";
        input-keys = <&soft_off_key>;
        wakeup-source;
    };
    soft_off_wakers {
        compatible = "zmk,soft-off-wakeup-sources";
        wakeup-sources = <&soft_off_scan>;
    };
};
```

Then bind `&soft_off` to the soft-off scan's key (per the ZMK doc's
dedicated-kscan pattern). Slide off → `&soft_off` fires → System OFF;
slide on → the wakeup source re-enables the board.

**Spare GPIO confirmed:** `P0` (and `P1`) break out to self-named nets on
the nice!nano footprint, used nowhere else in the matrix/encoder/display,
so P0 is free for this.

### Implementation status

- [x] Documented (this file) + rev1 frozen at `hw-rev1`
- [x] `thenar/ergogen/config.yaml`: battery+ off RAW → isolated
      `BAT_BPLUS` wire-out pad; slider → `SOFT_OFF` (nice!nano P0) / GND;
      silk labels. Validated: `ergogen` regenerates cleanly, `switch_from`
      gone, `BAT_BPLUS`/`SOFT_OFF` nets present.
- [x] Firmware soft-off scaffold documented (above), kept out of active
      firmware until there's hardware to validate it on
- [ ] **Re-route `thenar/routed/keyboard.kicad_pcb`** — it is now
      rev1-stale vs the rev2 ergogen source. Regenerate with
      `nix build .#routed-auto` (~25 min, ~95%), finish the last traces +
      DRC in KiCad, then `cp` into `thenar/routed/`. The `routing-check`
      flake check will fail until this is done (placement drifted).
- [ ] Bench-test soft-off + charge-while-off on a reworked board

---

## The hypothenar does NOT have the rev1 problem

The hypothenar is a from-scratch power design (MS88SF3 + its own TP4056 +
LDO + sense divider) that routes **everything to one `VBAT` net** — cell,
charger BAT pin, MCU VDDH, and a GPIO-switched ADC divider all share it —
so it senses and charges the real cell. See
`hypothenar-keyboard/docs/power-budget.md`. Because it has its *own*
charge IC (not the nice!nano's fused B+ node), a true **hard-off that
still charges** is designable there (battery always on the TP4056, a load
switch to the MCU) — a v-next consideration, not a v1 thing. Bring-up
check: confirm the divider's high side is on `VBAT` (post-slider).
