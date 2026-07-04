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
// TODO(v2): access hole for the power slider switch.
// TODO(v2): access hole for the reset button (or rely on double-tap via
//           keymap / tweezers through the USB notch).
// TODO(v2): battery pocket recessed into the floor.
// TODO(v2): standoffs/bosses under the screw points instead of relying on
//           the sockets resting on the floor.
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
}
