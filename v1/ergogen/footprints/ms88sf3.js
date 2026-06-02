// Auto-generated from ms88sf3.kicad_mod by _convert_kicad_mod.py.
// Original module: ms88sf3
// 64 pads, 64 unique pad numbers.
// Edit by hand only as a last resort; prefer re-running the script.

module.exports = {
  params: {
    designator: 'U',
    side: 'F',
    P1: undefined,    // pad "1"
    P2: undefined,    // pad "2"
    P3: undefined,    // pad "3"
    P4: undefined,    // pad "4"
    P5: undefined,    // pad "5"
    P6: undefined,    // pad "6"
    P7: undefined,    // pad "7"
    P8: undefined,    // pad "8"
    P9: undefined,    // pad "9"
    P10: undefined,    // pad "10"
    P11: undefined,    // pad "11"
    P12: undefined,    // pad "12"
    P13: undefined,    // pad "13"
    P14: undefined,    // pad "14"
    P15: undefined,    // pad "15"
    P16: undefined,    // pad "16"
    P17: undefined,    // pad "17"
    P18: undefined,    // pad "18"
    P19: undefined,    // pad "19"
    P20: undefined,    // pad "20"
    P21: undefined,    // pad "21"
    P22: undefined,    // pad "22"
    P23: undefined,    // pad "23"
    P24: undefined,    // pad "24"
    P25: undefined,    // pad "25"
    P26: undefined,    // pad "26"
    P27: undefined,    // pad "27"
    P28: undefined,    // pad "28"
    P29: undefined,    // pad "29"
    P30: undefined,    // pad "30"
    P31: undefined,    // pad "31"
    P32: undefined,    // pad "32"
    P33: undefined,    // pad "33"
    P34: undefined,    // pad "34"
    P35: undefined,    // pad "35"
    P36: undefined,    // pad "36"
    P37: undefined,    // pad "37"
    P38: undefined,    // pad "38"
    P39: undefined,    // pad "39"
    P40: undefined,    // pad "40"
    P41: undefined,    // pad "41"
    P42: undefined,    // pad "42"
    P43: undefined,    // pad "43"
    P44: undefined,    // pad "44"
    P45: undefined,    // pad "45"
    P46: undefined,    // pad "46"
    P47: undefined,    // pad "47"
    P48: undefined,    // pad "48"
    P49: undefined,    // pad "49"
    P50: undefined,    // pad "50"
    P51: undefined,    // pad "51"
    P52: undefined,    // pad "52"
    P53: undefined,    // pad "53"
    P54: undefined,    // pad "54"
    P55: undefined,    // pad "55"
    P56: undefined,    // pad "56"
    P57: undefined,    // pad "57"
    P58: undefined,    // pad "58"
    P59: undefined,    // pad "59"
    P60: undefined,    // pad "60"
    P61: undefined,    // pad "61"
    P62: undefined,    // pad "62"
    P63: undefined,    // pad "63"
    P64: undefined,    // pad "64"
  },
  body: p => {
    // For each pad, substitute the net by adding a `(net N "<name>")`
    // before the closing paren. ergogen handles the (net N) part via p.X.str.
    const padNet = (padNum) => {
      const ident = 'P' + String(padNum).replace(/[^A-Za-z0-9_]/g, '_');
      return p[ident] ? p[ident].str : '';
    };

    return `
    (module ms88sf3 (layer F.Cu) (tedit 0)
    ${p.at}
    (fp_text reference "${p.ref}" (at 0 -12) (layer ${p.side}.SilkS) ${p.ref_hide}
      (effects (font (size 1 1) (thickness 0.15))))
    (fp_text value "ms88sf3" (at 0 12) (layer ${p.side}.Fab) hide
      (effects (font (size 1 1) (thickness 0.15))))
      (pad "1" smd rect (at -5.6 -3.1) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("1")})
      (pad "2" smd rect (at -5.6 -2.45) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("2")})
      (pad "3" smd rect (at -5.6 -1.8) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("3")})
      (pad "4" smd rect (at -5.6 -1.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("4")})
      (pad "5" smd rect (at -5.6 -0.5) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("5")})
      (pad "6" smd rect (at -5.6 0.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("6")})
      (pad "7" smd rect (at -5.6 0.8) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("7")})
      (pad "8" smd rect (at -5.6 1.45) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("8")})
      (pad "9" smd rect (at -5.6 2.1) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("9")})
      (pad "10" smd rect (at -5.6 2.75) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("10")})
      (pad "11" smd rect (at -5.6 3.4) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("11")})
      (pad "12" smd rect (at -5.6 4.05) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("12")})
      (pad "13" smd rect (at -5.6 4.7) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("13")})
      (pad "14" smd rect (at -5.6 5.35) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("14")})
      (pad "15" smd rect (at -5.6 6) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("15")})
      (pad "16" smd rect (at -5.6 6.65) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("16")})
      (pad "17" smd rect (at -5.6 7.3) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("17")})
      (pad "18" smd rect (at -5.2 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("18")})
      (pad "19" smd rect (at -4.55 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("19")})
      (pad "20" smd rect (at -3.9 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("20")})
      (pad "21" smd rect (at -3.25 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("21")})
      (pad "22" smd rect (at -2.6 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("22")})
      (pad "23" smd rect (at -1.95 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("23")})
      (pad "24" smd rect (at -1.3 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("24")})
      (pad "25" smd rect (at -0.65 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("25")})
      (pad "26" smd rect (at 0 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("26")})
      (pad "27" smd rect (at 0.65 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("27")})
      (pad "28" smd rect (at 1.3 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("28")})
      (pad "29" smd rect (at 1.95 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("29")})
      (pad "30" smd rect (at 2.6 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("30")})
      (pad "31" smd rect (at 3.25 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("31")})
      (pad "32" smd rect (at 3.9 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("32")})
      (pad "33" smd rect (at 4.55 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("33")})
      (pad "34" smd rect (at 5.2 8.5) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("34")})
      (pad "35" smd rect (at 5.6 7.3) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("35")})
      (pad "36" smd rect (at 5.6 6.65) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("36")})
      (pad "37" smd rect (at 5.6 6) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("37")})
      (pad "38" smd rect (at 5.6 5.35) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("38")})
      (pad "39" smd rect (at 5.6 4.7) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("39")})
      (pad "40" smd rect (at 5.6 4.05) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("40")})
      (pad "41" smd rect (at 5.6 3.4) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("41")})
      (pad "42" smd rect (at 5.6 2.75) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("42")})
      (pad "43" smd rect (at 5.6 2.1) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("43")})
      (pad "44" smd rect (at 5.6 1.45) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("44")})
      (pad "45" smd rect (at 5.6 0.8) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("45")})
      (pad "46" smd rect (at 5.6 0.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("46")})
      (pad "47" smd rect (at 5.6 -0.5) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("47")})
      (pad "48" smd rect (at 5.6 -1.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("48")})
      (pad "49" smd rect (at 5.6 -1.8) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("49")})
      (pad "50" smd rect (at 5.6 -2.45) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("50")})
      (pad "51" smd rect (at 5.6 -3.1) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("51")})
      (pad "52" smd rect (at 4.55 -3) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("52")})
      (pad "53" smd rect (at 3.9 -3) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("53")})
      (pad "54" smd rect (at 3.25 -3) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("54")})
      (pad "55" smd rect (at 2.6 -3) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("55")})
      (pad "56" smd rect (at 1.95 -3) (size 0.35 0.8) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("56")})
      (pad "57" smd rect (at 3.9 -1.8) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("57")})
      (pad "58" smd rect (at 3.9 -1.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("58")})
      (pad "59" smd rect (at 3.9 -0.5) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("59")})
      (pad "60" smd rect (at 3.9 0.15) (size 0.8 0.35) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("60")})
      (pad "61" smd rect (at 1.25 0.4) (size 1 1.5) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("61")})
      (pad "62" smd rect (at 1.25 3.25) (size 1 1.5) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("62")})
      (pad "63" smd rect (at -1.55 3.25) (size 1 1.5) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("63")})
      (pad "64" smd rect (at -1.55 0.4) (size 1 1.5) (layers ${p.side}.Cu ${p.side}.Paste ${p.side}.Mask) ${padNet("64")})
      (fp_line (start 6.25 9.25) (end 5.695 9.25) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start 6.25 -9.25) (end 6.25 -3.65) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start -5.695 9.25) (end -6.25 9.25) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start -6.25 -9.25) (end 6.25 -9.25) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start -6.25 -3.65) (end -6.25 -9.25) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start 6.25 9.25) (end 6.25 7.8) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_line (start -6.25 9.25) (end -6.25 7.8) (layer ${p.side}.SilkS) (width 0.127) )
      (fp_circle (center -6.85 -3.1) (end -6.75 -3.1) (layer ${p.side}.SilkS) (width 0.2) (fill none) )
      (fp_line (start 6.5 -4.7) (end 11.25 -4.7) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start 11.25 -14.25) (end 11.25 -4.7) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -11.25 -14.25) (end 11.25 -14.25) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -11.25 -4.7) (end -11.25 -14.25) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start 6.5 9.5) (end 6.5 -4.7) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -6.5 -4.7) (end -11.25 -4.7) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -6.5 9.5) (end 6.5 9.5) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -6.5 -4.7) (end -6.5 9.5) (layer ${p.side}.CrtYd) (width 0.12) )
      (fp_line (start -6.25 9.25) (end -6.25 -4.7) (layer ${p.side}.Fab) (width 0.127) )
      (fp_line (start -6.25 -9.25) (end 6.25 -9.25) (layer ${p.side}.Fab) (width 0.127) )
      (fp_line (start -6.25 -4.7) (end -6.25 -9.25) (layer ${p.side}.Fab) (width 0.127) )
      (fp_line (start 6.25 -9.25) (end 6.25 -4.7) (layer ${p.side}.Fab) (width 0.127) )
      (fp_line (start 6.25 -4.7) (end 6.25 9.25) (layer ${p.side}.Fab) (width 0.127) )
      (fp_line (start 6.25 9.25) (end -6.25 9.25) (layer ${p.side}.Fab) (width 0.127) )
      (fp_circle (center -6.85 -3.1) (end -6.75 -3.1) (layer ${p.side}.Fab) (width 0.2) (fill none) )
    )
    `;
  },
};
