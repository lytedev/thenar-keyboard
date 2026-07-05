// Calibration coupon for the 3D-printed switch plate.
//
// Five 14mm Choc cutouts at increasing FDM shrink compensation,
// labeled with the compensation in hundredths of a mm (0, 10, 15, 20,
// 25). Print flat at the same settings you'll use for the real plate
// (0.15mm layers, 100% infill recommended), then press a Choc switch
// into each hole:
//
//   - too tight / needs force: move up
//   - clips engage with a firm push, no wobble: that's your value
//   - drops in loosely / wobbles: move down
//
// Then EITHER set that value as your slicer's hole-horizontal-
// expansion / XY-hole-compensation (and print the plate unmodified),
// OR rebuild the plate STL with -D print_compensation=<value>.
//
// Coupon is ~90x24mm, prints in ~10 minutes.
cutout = 14.0;          // matches switchplate_switch_cutout in ergogen
thickness = 1.3;        // match the plate
compensations = [0, 0.10, 0.15, 0.20, 0.25];
pitch = 18;             // spacing between cutout centres
margin = 2;

coupon_w = pitch * len(compensations) + margin * 2;
coupon_h = cutout + margin * 2 + 6;  // extra 6mm strip for labels

difference() {
  linear_extrude(height = thickness)
    square([coupon_w, coupon_h]);
  for (i = [0 : len(compensations) - 1]) {
    c = compensations[i];
    // Cutout, grown by the compensation on each side
    translate([margin + pitch * i + pitch / 2, margin + cutout / 2 + 6, -1])
      linear_extrude(height = thickness + 2)
        square(cutout + 2 * c, center = true);
    // Engraved label: compensation in hundredths (e.g. "15" = 0.15mm)
    translate([margin + pitch * i + pitch / 2, margin + 2, thickness - 0.4])
      linear_extrude(height = 1)
        text(str(c * 100), size = 3.5, halign = "center",
             font = "Liberation Sans:style=Bold");
  }
}
