{
  self,
  nixpkgs,
  systems,
  flake-parts,
  crane,
  rust-overlay,
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
    forCargoWorkspace = { systems, src }: {
      inherit systems;

      perSystem =
        { system, ... }:
        let
          pkgsWithRust = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          toolchain = pkgsWithRust.rust-bin.fromRustupToolchainFile (src + "/rust-toolchain.toml");
          craneLib = (crane.mkLib pkgsWithRust).overrideToolchain toolchain;
          commonArgs = {
            src = craneLib.cleanCargoSource src;
            strictDeps = true;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          package = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
        in
        {
          packages.default = package;
          checks = {
            default = package;
            clippy = craneLib.cargoClippy (
              commonArgs
              // {
                inherit cargoArtifacts;
                cargoClippyExtraArgs = "--all-targets -- --deny warnings";
              }
            );
          };
        };
    };
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
