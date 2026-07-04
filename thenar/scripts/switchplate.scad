// 3D-printable switch mid-plate for the thenar rc1.
//
// Extrudes the ergogen `switchplate` outline (which already carries the
// 14mm Choc switch cutouts and the scrollwheel cutout) and subtracts the
// mounting screw holes, which the PCB variant of the plate gets as KiCad
// footprints rather than as part of the DXF outline.
//
// The outline is a single half; print one as-is and one mirrored in the
// slicer for the other half.
//
// All parameters are overridable via `openscad -D`:
//   thickness       plate height in mm. Kailh Choc clips want 1.2-1.4.
//   dxf             path to the ergogen switchplate outline DXF.
//   screw_hole      mounting hole diameter in mm. Mirrors
//                   switchplate_screw_hole in ergogen/config.yaml.
//   screw_positions [[x, y], ...] hole centres in DXF coordinates, as
//                   emitted by scripts/switchplate_holes.py.
thickness = 1.3;
dxf = "switchplate.dxf";
screw_hole = 2.2;
screw_positions = [];

difference() {
  linear_extrude(height = thickness) import(dxf);
  for (p = screw_positions)
    translate([p[0], p[1], -1])
      cylinder(h = thickness + 2, d = screw_hole, $fn = 32);
}
