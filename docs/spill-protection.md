# Spill protection

Making the thenar survive a desk spill. This is **splash + humidity
resistance** — "I knocked my coffee over, cut power fast, let it dry" —
not submersion. Three layers, cheapest first; the coating is the one
that takes real work.

## 1. Behaviour (free, most important)

Electronics rarely die *wet*. They die *wet and powered* — electrolytic
corrosion and shorts happen while current flows. So the moment liquid
hits:

1. **Slide the power switch OFF** (cuts the battery at the board edge —
   no case-opening needed; the case v2 has a slot for it).
2. **Unplug USB.**
3. **Let it dry for days** before repowering. Rice/desiccant helps;
   heat above ~50 °C does not (bad for the LiPo).

The slider being a fast, accessible battery cutoff is why it earns its
place. This step alone saves most spilled boards.

## 2. Case drain slots (free, in case v2)

`thenar/scripts/case.scad` puts drain slots in the floor so liquid that
gets through the switch-plate cutouts exits instead of pooling against
the PCB. Print the current case (`nix build .#case-stl`).

## 3. Conformal coating (the real protection, ~$15 + care)

A thin insulating film over the electronics that shrugs off splashes
and humidity.

### Use acrylic, not silicone

For a **hotswap, tinkerable** board the deciding factor is
*reworkability*, not raw waterproofing:

- **Acrylic** (MG Chemicals 419D brush-on, or 4223 aerosol) is
  solvent-removable and you can still solder through it — so a future
  switch/diode fix stays possible. Cheap, easy, forgiving.
- **Silicone** repels liquid droplets slightly better but is miserable
  to rework or solder near, and actually allows ~10× more moisture
  *vapour* penetration than acrylic. Wrong trade for a board you open.

Sources: [acrylic vs silicone guide](https://www.andwinpcb.com/acrylic-vs-silicone-vs-urethane-conformal-coating-complete-selection-guide-for-pcb-protection/),
[Techspray essential guide](https://www.techspray.com/the-essential-guide-to-conformal-coating),
[Titoma waterproofing methods](https://titoma.com/blog/conformal-coating/).

### The skill is MASKING (do not skip)

Coating is easy; masking is where boards get bricked. Mask (keep BARE)
everything electromechanical or that mates / gets soldered. Coating a
contact kills it. Pre-flight mask list for the thenar:

- [ ] All 28 **hotswap sockets** (the leaf contacts)
- [ ] The **nice!nano header pins AND the female sockets**
- [ ] **USB-C** connector contacts + shield
- [ ] **SWD pads** and the **reset** tactile switch
- [ ] **Slider switch** contacts
- [ ] **Encoder** push + rotation pads
- [ ] **Display header** (nice!view)
- [ ] **Battery** solder pads / JST
- [ ] Screw holes (for clean threads) — optional

Coat freely everywhere else: the diodes, all traces, the passives, the
exposed copper between components.

Masking materials: Kapton tape is ideal (leaves no residue), or liquid
latex mask painted on and peeled off after. A toothpick lifts tape
edges cleanly.

### The nice!nano

**Leave it socketed; coat it separately or not at all.** It's a
replaceable daughterboard — the socket exists so you can swap it. If
you coat it, do so off-board with its pins masked; or skip it (it has
an RF shield can already, and you want its USB/charge circuitry
accessible). The **main PCB** is what benefits most.

### Application

- Do it **only after the board is 100 % working and you have stopped
  reflowing joints** — this is a finishing step, not a bring-up one.
- Two **thin** coats beat one thick one. Brush on, let flash off
  (~15 min for acrylic), second coat, then full cure per the can
  (hours). Ventilate.
- Test fit a switch into a masked socket after curing to confirm no
  coating crept into a contact.

## What NOT to do

- **Potting / epoxy fill** — permanent, un-repairable, kills hotswap.
  Wrong for a keyboard.
- **Mail-in "nano-coating" services** — overkill; DIY acrylic matches
  them for this use.
- Treating any of this as **submersion-proof**. It is not.
