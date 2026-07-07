{
  self,
  nixpkgs,
  systems,
  flake-parts,
}:

let
  systemsDefault = import systems;

  mkPerSystemOutputs =
    project: system:
    let
      pkgs = mkPkgs project system;
    in
    {
      packages.default = pkgs.stdenvNoCC.mkDerivation {
        pname = project.pname;
        version = project.version;
        src = project.src;

        installPhase = ''
          mkdir -p $out
          cp -r . $out/src
        '';
      };

      checks.default = pkgs.runCommand "${project.pname}-check" { } ''
        echo ok > $out
      '';
    };

  mkFlakePartsModule = {
    forCargoWorkspace = { systems, src }: { perSystem = { pkgs, inputs', ... }: (
      # TODO: use `rust-overlay` to select toolchain from `src + "/rust-toolchain.toml", then wrap the whole build with `crane`.

      ); };
  };

in
# lib interface:
{
  mkFlakeOutputs =
    {
      cargoWorkspace,
      systems ? systemsDefault,
    }:
    (flake-parts.lib.mkFlake { inputs = inputs; } {
      imports = [
        (mkFlakePartsModule.forCargoWorkspace {
          inherit systems;
          src = cargoWorkspace;
        })
      ];
    });
}
