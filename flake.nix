{
  description = "Thenar keyboard - ergogen + KiCad build pipeline + ZMK firmware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          # Python wrapper that can `import pcbnew`. KiCad ships its Python
          # module under kicad-base/lib/python3.13/site-packages; this wrapper
          # exposes that to a vanilla python3 interpreter.
          kicadPython = pkgs.writeShellScriptBin "kicad-python" ''
            export PYTHONPATH="${pkgs.kicad.base}/lib/python3.13/site-packages''${PYTHONPATH:+:$PYTHONPATH}"
            exec ${pkgs.python313}/bin/python3 "$@"
          '';

          # nixpkgs ships freerouting 2.2.1, which has a multithreaded race that
          # crashes pass #1 with a NullPointerException on our DSN. v2.2.4
          # ships several stability fixes upstream; pull the JAR directly and
          # wrap it. Drop this when nixpkgs updates.
          freeroutingJar = pkgs.fetchurl {
            url = "https://github.com/freerouting/freerouting/releases/download/v2.2.4/freerouting-2.2.4.jar";
            hash = "sha256-9e03QYKQDMx45HNRi7ufa4afSgcVlJX2Y6dvUrsQUjs=";
          };
          # Need full JRE (not jre25_minimal) - freerouting references
          # javax.swing classes even in CLI mode.
          freerouting = pkgs.writeShellScriptBin "freerouting" ''
            exec ${pkgs.temurin-jre-bin-25}/bin/java -jar ${freeroutingJar} "$@"
          '';

          # Ergogen scaffold + project file generation. NOT FAB-READY by itself:
          # this has footprints + nets but no copper traces. Open the resulting
          # .kicad_pro in KiCad and route, or use .#gerbers (which builds from
          # the committed routed PCB) instead.
          scaffold = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-scaffold";
            src = ./thenar;
            nativeBuildInputs = [ pkgs.ergogen pkgs.python313 pkgs.kicad kicadPython ];
            buildPhase = ''
              runHook preBuild
              # KiCad's wxWidgets-based config loader needs a writable HOME.
              export HOME=$(mktemp -d)
              mkdir -p $out
              ergogen ./ergogen -o $out
              # Ergogen emits KiCad 5.1 format. Upgrade to current format
              # first - pcbnew Python segfaults if you save a board twice in
              # one process (which is what migrate-then-modify would need).
              kicad-cli pcb upgrade $out/pcbs/keyboard.kicad_pcb
              kicad-cli pcb upgrade $out/pcbs/switchplate.kicad_pcb
              # Only the keyboard PCB gets a project file - the switchplate is
              # an outline-only board (never hand-routed) and a sibling
              # switchplate.kicad_pro in the same directory would conflict with
              # keyboard.kicad_pro in KiCad's launcher.
              python3 ./scripts/write_kicad_pro.py $out/pcbs/keyboard.kicad_pcb
              # Add F.Cu + B.Cu GND zones so the user does not have to route
              # ground returns. Zones are added unfilled - gerber export passes
              # --check-zones to fill them at the time of fabrication output.
              kicad-python ./scripts/patch_keyboard_pcb.py $out/pcbs/keyboard.kicad_pcb
              runHook postBuild
            '';
            dontInstall = true;
          };

          # The hand-routed PCBs live in-tree. Gerbers are built from these, not
          # from the ergogen scaffold (which has no traces).
          routedKeyboard = ./thenar/routed/keyboard.kicad_pcb;
          routedSwitchplate = ./thenar/routed/switchplate.kicad_pcb;

          # Autoroute the scaffold via freerouting. Output is a kicad_pcb with
          # traces baked in. NOT used by .#gerbers by default - the committed
          # thenar/routed/ takes precedence so a careful hand-routed PCB does
          # not get clobbered by autorouter output. To use this:
          #   nix build .#routed-auto
          #   cp result/keyboard.kicad_pcb thenar/routed/keyboard.kicad_pcb
          # Pass count controls quality vs runtime: 50 ~25min, gets ~95% routed.
          routed-auto = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-routed-auto";
            src = ./thenar;
            nativeBuildInputs = [ pkgs.kicad kicadPython freerouting ];
            buildPhase = ''
              runHook preBuild
              export HOME=$(mktemp -d)
              # Re-derive a fresh kicad_pcb from the scaffold so this stage is
              # not coupled to whatever is currently in thenar/routed/.
              cp ${scaffold}/pcbs/keyboard.kicad_pcb $TMPDIR/in.kicad_pcb
              chmod u+w $TMPDIR/in.kicad_pcb
              mkdir -p $out
              kicad-python ./scripts/autoroute.py \
                $TMPDIR/in.kicad_pcb $out/keyboard.kicad_pcb 50
              runHook postBuild
            '';
            dontInstall = true;
          };

          gerbers = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-gerbers";
            nativeBuildInputs = [ pkgs.kicad ];
            dontUnpack = true;
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              kicad-cli pcb export gerbers \
                --subtract-soldermask \
                --check-zones \
                -l "F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" \
                ${routedKeyboard} -o $out
              kicad-cli pcb export drill \
                --generate-map --map-format gerberx2 --excellon-separate-th \
                ${routedKeyboard} -o $out/
              runHook postBuild
            '';
            dontInstall = true;
          };

          gerbers-zip = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-gerbers.zip";
            nativeBuildInputs = [ pkgs.zip ];
            dontUnpack = true;
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              (cd ${gerbers} && zip -r $out/thenar-gerbers.zip .)
              runHook postBuild
            '';
            dontInstall = true;
          };

          switchplate-step = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-switchplate.step";
            nativeBuildInputs = [ pkgs.kicad ];
            dontUnpack = true;
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              kicad-cli pcb export step ${routedSwitchplate} -o $out/switchplate.step
              sed -i -e "s/1\.6)/1.2)/g" $out/switchplate.step
              runHook postBuild
            '';
            dontInstall = true;
          };

          # FDM shrink compensation baked into the switchplate STL, in mm
          # per cutout side. Calibrated 2026-07-06 with the
          # .#switchplate-cal-stl coupon on Daniel's printer at 0.1mm
          # layers with slowed outer walls - the "15" cutout was the
          # right fit (tight, no warping). Set to 0 for a CAD-true STL
          # (e.g. if compensating in the slicer instead - don't do both).
          switchplateCompensation = "0.15";

          # 3D-printable switch mid-plate. Extrudes the ergogen `switchplate`
          # outline (14mm Choc cutouts + scrollwheel cutout baked in) to
          # 1.3mm - within the 1.2-1.4mm band Kailh Choc clips engage - and
          # subtracts the mounting screw holes, which the PCB variant gets
          # as footprints rather than as part of the DXF outline. The
          # outline is a single half: print one as-is, mirror in the slicer
          # for the other half. Thickness/hole size are -D overridable in
          # thenar/scripts/switchplate.scad.
          switchplate-stl = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-switchplate.stl";
            src = ./thenar;
            nativeBuildInputs = [ pkgs.ergogen pkgs.openscad pkgs.python313 ];
            buildPhase = ''
              runHook preBuild
              export HOME=$(mktemp -d)
              # --debug additionally emits points/points.yaml, which is
              # where the screw hole centres come from.
              ergogen ./ergogen -o $TMPDIR/ergogen --debug
              screws=$(python3 ./scripts/switchplate_holes.py \
                $TMPDIR/ergogen/points/points.yaml)
              mkdir -p $out
              openscad \
                -D "dxf=\"$TMPDIR/ergogen/outlines/switchplate.dxf\"" \
                -D "screw_positions=$screws" \
                -D "print_compensation=${switchplateCompensation}" \
                -o $out/switchplate.stl \
                ./scripts/switchplate.scad
              runHook postBuild
            '';
            dontInstall = true;
          };

          # 3D-printable bottom case tray. Offsets the ergogen `board`
          # Calibration coupon for dialing in FDM cutout compensation
          # before printing a full plate: five labeled 14mm Choc cutouts
          # at 0/0.10/0.15/0.20/0.25mm compensation. Press-fit a switch
          # into each; the label that clips firmly without wobble is your
          # slicer's hole-horizontal-expansion value (or rebuild the
          # plate with -D print_compensation=<value>).
          switchplate-cal-stl = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-switchplate-cal.stl";
            src = ./thenar;
            nativeBuildInputs = [ pkgs.openscad pkgs.liberation_ttf pkgs.fontconfig ];
            buildPhase = ''
              runHook preBuild
              export HOME=$(mktemp -d)
              # The coupon engraves text labels; point fontconfig at
              # liberation so `text()` resolves the font in the sandbox.
              export FONTCONFIG_FILE=$(mktemp)
              cat > $FONTCONFIG_FILE << EOF
              <?xml version="1.0"?>
              <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
              <fontconfig>
                <dir>${pkgs.liberation_ttf}/share/fonts</dir>
                <cachedir>$HOME/fontcache</cachedir>
              </fontconfig>
              EOF
              mkdir -p $out
              openscad -o $out/switchplate-cal.stl ./scripts/switchplate-cal.scad
              runHook postBuild
            '';
            dontInstall = true;
          };

          # outline outward for the perimeter wall (the `case` outline is
          # the same perimeter with screw holes pre-subtracted, which
          # offset() would distort, so the holes are cut in OpenSCAD
          # instead), floors it, and subtracts the switchplate screw
          # holes plus a USB-C notch located from the mcu ergogen point.
          # Like the switchplate, the outline is a single half: print one
          # as-is, mirror in the slicer for the other. Wall/floor/
          # clearance dimensions are -D overridable in
          # thenar/scripts/case.scad.
          case-stl = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-case.stl";
            src = ./thenar;
            nativeBuildInputs = [ pkgs.ergogen pkgs.openscad pkgs.python313 ];
            buildPhase = ''
              runHook preBuild
              export HOME=$(mktemp -d)
              # --debug additionally emits points/points.yaml, which is
              # where the screw hole and mcu centres come from.
              ergogen ./ergogen -o $TMPDIR/ergogen --debug
              screws=$(python3 ./scripts/switchplate_holes.py \
                $TMPDIR/ergogen/points/points.yaml)
              mcu=$(python3 ./scripts/switchplate_holes.py \
                $TMPDIR/ergogen/points/points.yaml mcu)
              mkdir -p $out
              openscad \
                -D "dxf=\"$TMPDIR/ergogen/outlines/board.dxf\"" \
                -D "screw_positions=$screws" \
                -D "usb_positions=$mcu" \
                -o $out/case.stl \
                ./scripts/case.scad
              runHook postBuild
            '';
            dontInstall = true;
          };

          # Verify that the routed PCB's footprint placement matches the current
          # ergogen scaffold. If you edit thenar/ergogen/config.yaml without
          # re-merging into thenar/routed/, this check fails.
          check-routing-drift = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-check-routing-drift";
            nativeBuildInputs = [ pkgs.kicad pkgs.diffutils ];
            dontUnpack = true;
            buildPhase = ''
              runHook preBuild
              kicad-cli pcb export pos ${scaffold}/pcbs/keyboard.kicad_pcb \
                -o ergogen.csv --format csv --units mm --side both
              kicad-cli pcb export pos ${routedKeyboard} \
                -o routed.csv --format csv --units mm --side both
              sort ergogen.csv > ergogen.sorted.csv
              sort routed.csv > routed.sorted.csv
              if ! diff -u ergogen.sorted.csv routed.sorted.csv; then
                echo ""
                echo "ERROR: footprint placement in thenar/routed/keyboard.kicad_pcb"
                echo "does not match the current ergogen output."
                echo ""
                echo "Re-run 'nix build .#scaffold' and merge the new placement"
                echo "into thenar/routed/ in KiCad before building gerbers."
                exit 1
              fi
              mkdir -p $out
              cp ergogen.sorted.csv $out/placement.csv
              runHook postBuild
            '';
            dontInstall = true;
          };

          # ZMK firmware build. zmk-nix's buildSplitKeyboard handles the
          # zephyr SDK + west + arm-gcc plumbing; we just point it at our
          # shield + west manifest under config/.
          #
          # First build will fail with a hash mismatch - paste the hash nix
          # reports into zephyrDepsHash below and rebuild.
          firmware = zmk-nix.legacyPackages.${pkgs.system}.buildSplitKeyboard {
            name = "thenar-firmware";
            src = nixpkgs.lib.sourceFilesBySuffices self [
              ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
              ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
            ];
            board = "nice_nano";
            # Include the nice!view shields (matches config/build.yaml).
            # Safe with no display attached: the LS0xx SPI writes are
            # fire-and-forget, so the same image works bare or with a
            # display socketed in later.
            shield = "thenar_%PART% nice_view_adapter nice_view";
            # Hash for the zmk v0.3.0 dependency snapshot (west.yml pin).
            zephyrDepsHash = "sha256-gsqiTDJLAihVyBXVFlgXwqRmlREcFJctKpl4tEWmVlY=";
          };

          # Settings-reset image (wipes BLE bonds; flash, boot once, then
          # reflash real firmware - the fix for split-pairing weirdness).
          # NOTE: name deliberately matches the main firmware: zmk-nix
          # names its west-deps fixed-output derivation "\${name}-west-deps",
          # so sharing the name makes this build reuse the ALREADY-FETCHED
          # ~1.5GB deps tree instead of re-fetching identical content under
          # a new store name. (Upstream zmk-nix would ideally key deps by
          # manifest hash, not consumer name.)
          firmware-reset = zmk-nix.legacyPackages.${pkgs.system}.buildKeyboard {
            name = "thenar-firmware";
            src = nixpkgs.lib.sourceFilesBySuffices self [
              ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
              ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
            ];
            board = "nice_nano";
            shield = "settings_reset";
            zephyrDepsHash = "sha256-gsqiTDJLAihVyBXVFlgXwqRmlREcFJctKpl4tEWmVlY=";
          };

          firmware-left = pkgs.runCommand "thenar-left.uf2" { } ''
            cp ${firmware}/zmk_left.uf2 $out
          '';
          firmware-right = pkgs.runCommand "thenar-right.uf2" { } ''
            cp ${firmware}/zmk_right.uf2 $out
          '';

          # `nix run .#flash -- left` or `... -- right` builds the firmware
          # for the requested half, then waits for a Nice!Nano to mount in
          # bootloader mode and copies the .uf2 onto it. Convenience over
          # zmk-nix's generic flash helper because we want left/right args.
          flash = pkgs.writeShellApplication {
            name = "flash";
            runtimeInputs = [ pkgs.util-linux pkgs.coreutils ];
            text = ''
              set -euo pipefail
              if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^(left|right)$ ]]; then
                echo "usage: nix run .#flash -- (left|right)" >&2
                exit 2
              fi
              part=$1
              uf2=${firmware}/zmk_$part.uf2
              if [ ! -f "$uf2" ]; then
                echo "error: $uf2 not found - did the build succeed?" >&2
                exit 1
              fi
              echo "[flash] firmware ready: $uf2"
              echo "[flash] double-tap reset on the $part-hand Nice!Nano now."
              echo "[flash] waiting for NICENANO mass-storage to appear..."
              while :; do
                mount=$(lsblk -o LABEL,MOUNTPOINT -nr | awk '$1=="NICENANO" {print $2; exit}')
                if [ -n "$mount" ]; then break; fi
                sleep 1
              done
              echo "[flash] mounted at $mount; copying..."
              cp "$uf2" "$mount/"
              sync
              echo "[flash] done. The Nice!Nano will reboot and unmount automatically."
            '';
          };

        in
        {
          inherit scaffold gerbers gerbers-zip switchplate-step switchplate-stl
                  switchplate-cal-stl case-stl
                  check-routing-drift kicadPython routed-auto freerouting
                  firmware firmware-reset firmware-left firmware-right flash;
          default = gerbers-zip;
        });

      apps = forAllSystems (pkgs: {
        flash = {
          type = "app";
          program = "${self.packages.${pkgs.system}.flash}/bin/flash";
        };
      });

      checks = forAllSystems (pkgs: {
        routing-drift = self.packages.${pkgs.system}.check-routing-drift;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ergogen
            kicad
            zip
            python313
            self.packages.${pkgs.system}.kicadPython
            self.packages.${pkgs.system}.freerouting
          ];
        };
      });
    };
}
