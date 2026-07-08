// 3D-printable bottom case tray for the thenar rc1.
//
// A simple tray the PCB sits in, component-side-down: a flat floor plus a
// perimeter wall grown as an outward offset of the ergogen `board` outline,
// so the cavity interior matches the PCB outline plus a small fit
// clearance. Wall height clears the Kailh Choc hotswap sockets (~3mm)
// under the PCB (1.6mm) with margin. The switchplate mounting screws pass
// through the floor at the same `screw`-tagged ergogen points the plate
// uses, with a shallow countersink on the underside for M2 flat heads.
// A full-height open-top notch in the wall clears the nice!nano's USB-C
// connector; its centre comes from the `mcu`-tagged ergogen point and it
// opens in +y (the nice!nano sits long-axis vertical with USB at the
// board's top edge).
//
// The outline is a single half; print one as-is and one mirrored in the
// slicer for the other half.
//
// v2 additions:
//   - Power slider access: the E73:SPDT_C128955 is an SMD slide switch
//     mounted component-side-down, so its actuator faces the case floor.
//     A floor slot under it, elongated along the actuator's travel axis,
//     lets you slide it with a fingernail/tool through the closed case.
//     Its position is derived from the same `mcu` ergogen point the USB
//     notch uses (slider = mcu point + slider_offset), so it can't drift.
//   - Drain slots: a few floor slots in the key area (away from the
//     battery/electronics zone at the top) so a desk spill that gets
//     through the switch plate exits instead of pooling on the PCB.
//
// NOT case concerns (corrected 2026-07): the reset button and the
// nice!nano charge LED are both on the TOP face; the case is a bottom
// tray, so it neither blocks nor needs to expose them.
//
// TODO(v2): battery pocket recessed into the floor.
// TODO(v2): standoffs/bosses under the screw points instead of relying on
//           the sockets resting on the floor.
// TODO(v2): VERIFY the encoder wheel-to-floor clearance on a printed
//           case. The EVQWGD001 mounts component-side-down; whether its
//           roller touches the floor depends on which component the PCB
//           rests on (sockets vs the encoder body) - not determinable
//           from the 2D footprint. wall_height gives ~5.4mm under-PCB
//           space; the encoder's under-board depth is ~4-5mm per the
//           datasheet, so it likely clears, but measure to be sure.
//
// All parameters are overridable via `openscad -D`:
//   dxf              path to the ergogen board outline DXF (the case
//                    perimeter; `case.dxf` is this same outline with the
//                    screw holes pre-subtracted, which offset() would
//                    distort, so the plain board outline is used and the
//                    holes are cut as cylinders below).
//   floor_thickness  floor plate height in mm.
//   wall_height      wall height above the floor in mm. Must clear
//                    hotswap sockets (~3mm) + PCB (1.6mm) + margin.
//   wall_thickness   perimeter wall thickness in mm.
//   clearance        gap between PCB outline and cavity interior in mm.
//   screw_hole       screw hole diameter in mm. Mirrors
//                    switchplate_screw_hole in ergogen/config.yaml.
//   screw_positions  [[x, y], ...] hole centres in DXF coordinates, as
//                    emitted by scripts/switchplate_holes.py.
//   csink_diameter / csink_depth
//                    underside countersink for the screw heads. Set
//                    csink_depth = 0 to disable.
//   usb_positions    [[x, y]] mcu point centre in DXF coordinates, as
//                    emitted by `scripts/switchplate_holes.py ... mcu`.
//   usb_dir          direction the USB connector faces, degrees in the
//                    DXF plane (90 = +y).
//   usb_notch_width  width of the USB wall notch in mm.
dxf = "board.dxf";
floor_thickness = 2.0;
wall_height = 7.0;
wall_thickness = 2.0;
clearance = 0.25;
screw_hole = 2.2;
screw_positions = [];
csink_diameter = 4.6;
csink_depth = 1.2;
usb_positions = [];
usb_dir = 90;
usb_notch_width = 14;
// How far the notch cutter reaches inward/outward from the mcu centre.
// Generous on purpose: inside the cavity it only cuts air.
usb_notch_reach = 30;

// Power slider floor slot. Position derived from the mcu point (which is
// passed in as usb_positions[0]): the slider zone is anchored to `mcu`
// with adjust.shift [-17.1, 0] in ergogen space, which lands +17.1mm in
// DXF y from the mcu centre. Slot elongated along the actuator's travel
// (the footprint is rotate:90, so travel runs along y = the board edge).
slider_offset = [0, 17.1];   // DXF offset from the mcu point to the slider
slider_slot_w = 5;           // across the actuator (x)
slider_slot_l = 11;          // along the travel axis (y): knob + full throw + finger
slider_slot_dir = 90;        // travel-axis direction, degrees (90 = +y)

// Drain slots in the floor (DXF coords), away from the top electronics
// zone. Board bbox is x 46..183, y -158..-48; these sit in the key area.
drain_positions = [[80, -112], [108, -122], [136, -116], [100, -96]];
drain_slot_w = 2;
drain_slot_l = 8;

eps = 0.01;
total_height = floor_thickness + wall_height;

difference() {
  union() {
    // Floor: full outline grown to the wall's outer face.
    linear_extrude(height = floor_thickness)
      offset(r = wall_thickness + clearance) import(dxf);
    // Wall ring: outer face minus cavity (outline + fit clearance).
    // offset(r=...) rather than offset(delta=...) so concave corners
    // of the outline don't self-intersect.
    linear_extrude(height = total_height) difference() {
      offset(r = wall_thickness + clearance) import(dxf);
      offset(r = clearance) import(dxf);
    }
  }

  // Switchplate mounting screws pass through the floor.
  for (p = screw_positions) {
    translate([p[0], p[1], -1])
      cylinder(h = total_height + 2, d = screw_hole, $fn = 32);
    if (csink_depth > 0)
      translate([p[0], p[1], -eps])
        cylinder(h = csink_depth, d1 = csink_diameter, d2 = screw_hole,
                 $fn = 32);
  }

  // USB-C notch: full wall height, open-top, floor left intact.
  for (p = usb_positions)
    translate([p[0], p[1], 0]) rotate([0, 0, usb_dir - 90])
      translate([-usb_notch_width / 2, 0, floor_thickness])
        cube([usb_notch_width, usb_notch_reach, wall_height + 1]);

  // Power slider access: a slot straight through the floor under the
  // slider's actuator, elongated along its travel axis.
  for (p = usb_positions)
    translate([p[0] + slider_offset[0], p[1] + slider_offset[1], -eps])
      rotate([0, 0, slider_slot_dir - 90])
        translate([-slider_slot_w / 2, -slider_slot_l / 2, 0])
          cube([slider_slot_w, slider_slot_l, floor_thickness + 2 * eps]);

  // Drain slots: small through-floor slots so a spill exits the tray.
  for (p = drain_positions)
    translate([p[0] - drain_slot_w / 2, p[1] - drain_slot_l / 2, -eps])
      cube([drain_slot_w, drain_slot_l, floor_thickness + 2 * eps]);
}
