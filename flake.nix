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
          # Run ergogen against thenar/ergogen/ and produce the full output tree
          # (outlines/*.dxf, pcbs/keyboard.kicad_pcb, pcbs/switchplate.kicad_pcb, ...).
          pcbs = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-pcbs";
            src = ./thenar/ergogen;
            nativeBuildInputs = [ pkgs.ergogen ];
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              ergogen . -o $out
              runHook postBuild
            '';
            dontInstall = true;
          };

          # Export gerbers + drill files from the generated keyboard PCB.
          gerbers = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-gerbers";
            src = pcbs;
            nativeBuildInputs = [ pkgs.kicad ];
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              kicad-cli pcb export gerbers \
                --subtract-soldermask \
                -l "F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" \
                pcbs/keyboard.kicad_pcb -o $out
              kicad-cli pcb export drill \
                --generate-map --map-format gerberx2 --excellon-separate-th \
                pcbs/keyboard.kicad_pcb -o $out/
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

          # Export the switchplate as a STEP model with a 1.2mm thickness.
          switchplate-step = pkgs.stdenvNoCC.mkDerivation {
            name = "thenar-switchplate.step";
            src = pcbs;
            nativeBuildInputs = [ pkgs.kicad ];
            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              kicad-cli pcb export step pcbs/switchplate.kicad_pcb -o $out/switchplate.step
              sed -i -e "s/1\.6)/1.2)/g" $out/switchplate.step
              runHook postBuild
            '';
            dontInstall = true;
          };
        in
        {
          inherit pcbs gerbers gerbers-zip switchplate-step;
          default = pcbs;
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ergogen
            kicad
            zip
          ];
        };
      });
    };
}
