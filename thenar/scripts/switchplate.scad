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
// FDM printers produce interior cutouts 0.1-0.3mm undersized, so a
// plate printed at CAD dimensions grips switches too tightly. Two ways
// to compensate - pick ONE:
//   1. (preferred, no rebuild) slicer-side: Cura "Hole Horizontal
//      Expansion" or PrusaSlicer/Orca "XY hole compensation",
//      typically 0.15-0.25mm. Print scripts/switchplate-cal.scad
//      first to find your printer's value.
//   2. model-side: -D print_compensation=0.15 - grows every interior
//      cutout by that amount per side via offset(delta=-c). Side
//      effect: the outer perimeter shrinks by the same amount, which
//      is negligible at these values.
//
// All parameters are overridable via `openscad -D`:
//   thickness           plate height in mm. Kailh Choc clips want 1.2-1.4.
//   dxf                 path to the ergogen switchplate outline DXF.
//   screw_hole          mounting hole diameter in mm. Mirrors
//                       switchplate_screw_hole in ergogen/config.yaml.
//   screw_positions     [[x, y], ...] hole centres in DXF coordinates, as
//                       emitted by scripts/switchplate_holes.py.
//   print_compensation  mm of FDM shrink compensation per cutout side.
//                       Default 0 = CAD-true; use the slicer knob instead
//                       when possible.
thickness = 1.3;
dxf = "switchplate.dxf";
screw_hole = 2.2;
screw_positions = [];
print_compensation = 0;

difference() {
  linear_extrude(height = thickness)
    // offset(delta=-c) grows interior holes and shrinks the outer
    // boundary by c; at 0 it's a no-op.
    offset(delta = -print_compensation) import(dxf);
  for (p = screw_positions)
    translate([p[0], p[1], -1])
      cylinder(h = thickness + 2, d = screw_hole + 2 * print_compensation, $fn = 32);
}
