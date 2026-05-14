{
  description = "Thenar keyboard - ergogen + KiCad build pipeline";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
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
            nativeBuildInputs = [ pkgs.kicad kicadPython pkgs.freerouting ];
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
        in
        {
          inherit scaffold gerbers gerbers-zip switchplate-step
                  check-routing-drift kicadPython routed-auto;
          default = gerbers-zip;
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
          ];
        };
      });
    };
}
