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
            shield = "thenar_%PART%";
            zephyrDepsHash = "sha256-emLUrBuHwtniwD7dtJBOkZwaltHz/n1OCJ35mxY7t38=";
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

          ###############################################################
          # ============================  v1  ============================
          ###############################################################
          # v1 derivations live alongside rc1 so both can be built from
          # the same checkout. rc1 stays the validated baseline; v1 is
          # the PCBA redesign per docs/v1-design.md.

          # v1 scaffold: ergogen run on v1/ergogen/. Same pattern as rc1
          # but only emits the keyboard PCB (no switchplate).
          v1-scaffold = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-v1-scaffold";
            src = ./v1;
            nativeBuildInputs = [ pkgs.ergogen pkgs.python313 pkgs.kicad kicadPython ];
            buildPhase = ''
              runHook preBuild
              export HOME=$(mktemp -d)
              mkdir -p $out
              ergogen ./ergogen -o $out
              kicad-cli pcb upgrade $out/pcbs/keyboard.kicad_pcb
              # Reuse rc1's project-file generator. POWER_NETS for v1
              # differs from rc1 (VBAT vs BAT+, no RAW); the script reads
              # the actual net list out of the PCB and matches on the
              # name patterns, so the rc1 default list is a strict
              # superset that works here. Pass the whole scripts dir so
              # the script's sibling template JSON is found at runtime.
              python3 ${./thenar/scripts}/write_kicad_pro.py \
                $out/pcbs/keyboard.kicad_pcb
              runHook postBuild
            '';
            dontInstall = true;
          };

          # v1 routed PCBs - one per half, no reversibility. These will
          # exist after Stage 4 of the build recipe; until then both paths
          # may not exist and v1-gerbers will fail with a clear message.
          v1RoutedLeft = ./v1/routed/keyboard-left.kicad_pcb;
          v1RoutedRight = ./v1/routed/keyboard-right.kicad_pcb;

          # v1 firmware - zmk-nix on v1/zmk/. zmk-nix expects the west
          # manifest at <src>/config/west.yml, so we materialise a src
          # tree with v1/zmk copied to config/.
          v1FirmwareSrc = pkgs.runCommand "thenar-v1-zmk-src" { } ''
            mkdir -p $out/config
            cp -r ${./v1/zmk}/. $out/config/
          '';

          v1-firmware = zmk-nix.legacyPackages.${pkgs.system}.buildSplitKeyboard {
            name = "thenar-v1-firmware";
            src = v1FirmwareSrc;
            board = "thenar_v1";
            shield = "thenar_v1_%PART%";
            # First build will fail with a hash mismatch - paste the hash
            # nix reports into this field. v1 pulls a different set of
            # Zephyr modules than rc1 (mcp23017 driver in particular) so
            # the hash does not match.
            zephyrDepsHash = pkgs.lib.fakeHash;
          };

          v1-firmware-left = pkgs.runCommand "thenar-v1-left.uf2" { } ''
            cp ${v1-firmware}/zmk_left.uf2 $out
          '';
          v1-firmware-right = pkgs.runCommand "thenar-v1-right.uf2" { } ''
            cp ${v1-firmware}/zmk_right.uf2 $out
          '';

          v1-flash = pkgs.writeShellApplication {
            name = "v1-flash";
            runtimeInputs = [ pkgs.util-linux pkgs.coreutils ];
            text = ''
              set -euo pipefail
              if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^(left|right)$ ]]; then
                echo "usage: nix run .#v1-flash -- (left|right)" >&2
                exit 2
              fi
              part=$1
              uf2=${v1-firmware}/zmk_$part.uf2
              if [ ! -f "$uf2" ]; then
                echo "error: $uf2 not found - did the build succeed?" >&2
                exit 1
              fi
              echo "[v1-flash] firmware ready: $uf2"
              echo "[v1-flash] double-tap reset on the $part-hand thenar v1 now."
              # The Adafruit nRF52 bootloader presents NICENANO regardless
              # of which custom board it's flashed onto - same UF2 volume
              # label as the rc1 boards. (One of the reasons we picked
              # the nice_nano_v2 bootloader build.)
              echo "[v1-flash] waiting for NICENANO mass-storage to appear..."
              while :; do
                mount=$(lsblk -o LABEL,MOUNTPOINT -nr | awk '$1=="NICENANO" {print $2; exit}')
                if [ -n "$mount" ]; then break; fi
                sleep 1
              done
              echo "[v1-flash] mounted at $mount; copying..."
              cp "$uf2" "$mount/"
              sync
              echo "[v1-flash] done. The board will reboot and unmount automatically."
            '';
          };

          # v1 PCBA artifacts: pick-place (CPL) CSV + a starter BOM CSV
          # for JLCPCB. Both are derived from the routed PCBs of each
          # half. The pick-place CSV maps footprints to (X, Y, side, rot)
          # and matches JLCPCB's expected header line.
          v1-pcba = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-v1-pcba";
            nativeBuildInputs = [ pkgs.kicad ];
            dontUnpack = true;
            buildPhase = ''
              runHook preBuild
              if [ ! -f ${v1RoutedLeft} ] || [ ! -f ${v1RoutedRight} ]; then
                echo "ERROR: v1/routed/keyboard-left.kicad_pcb or -right.kicad_pcb"
                echo "is missing. Complete Stage 4 of docs/v1-build-recipe.md"
                echo "(route the scaffold) before running v1-pcba."
                exit 1
              fi
              mkdir -p $out
              for half in left right; do
                src=${v1RoutedLeft}
                [ "$half" = right ] && src=${v1RoutedRight}
                kicad-cli pcb export pos "$src" \
                  -o "$out/thenar-v1-$half-cpl.csv" \
                  --format csv --units mm --side both \
                  --use-drill-file-origin
                # Re-shape header to JLCPCB's expected column names.
                # KiCad emits: Ref,Val,Package,PosX,PosY,Rot,Side
                # JLCPCB wants: Designator,Mid X,Mid Y,Layer,Rotation
                awk -F, 'NR==1 {
                  print "Designator,Mid X,Mid Y,Layer,Rotation"; next
                } { gsub(/"/, "")
                   side = $7 == "top" ? "T" : "B"
                   printf "%s,%s,%s,%s,%s\n", $1, $4, $5, side, $6
                }' "$out/thenar-v1-$half-cpl.csv" > "$out/thenar-v1-$half-cpl.jlc.csv"
              done
              runHook postBuild
            '';
            dontInstall = true;
          };
        in
        {
          inherit scaffold gerbers gerbers-zip switchplate-step
                  check-routing-drift kicadPython routed-auto freerouting
                  firmware firmware-left firmware-right flash
                  v1-scaffold v1-firmware v1-firmware-left v1-firmware-right
                  v1-flash v1-pcba;
          default = gerbers-zip;
        });

      apps = forAllSystems (pkgs: {
        flash = {
          type = "app";
          program = "${self.packages.${pkgs.system}.flash}/bin/flash";
        };
        v1-flash = {
          type = "app";
          program = "${self.packages.${pkgs.system}.v1-flash}/bin/v1-flash";
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
