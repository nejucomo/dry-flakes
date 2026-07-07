{
  self,
  nixpkgs,
  systems,
  flake-parts,
  crane,
  rust-overlay,
}@inputs:

let
  systemsDefault = import systems;

  mkFlakePartsModule = {
    forCargoWorkspace = { systems, src }: {
      inherit systems;

      perSystem =
        { self', system, ... }:
        let
          pkgsWithRust = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          toolchain = (pkgsWithRust.rust-bin.fromRustupToolchainFile (src + "/rust-toolchain.toml")).override {
            extensions = [
              "clippy"
              "rust-analyzer"
              "rustfmt"
            ];
          };
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
          devShells.default = craneLib.devShell {
            checks = self'.checks;
            packages = [ toolchain ];
          };
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
