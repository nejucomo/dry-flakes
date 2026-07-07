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

in
rec {
  mkFlakePartsModule = project: {
    systems = project.systems or systemsDefault;

    perSystem = { system, ... }: mkPerSystemOutputs project system;
  };

  mkFlakeUtilsOutputs =
    project: inputs.flake-utils.lib.eachDefaultSystem (system: mkPerSystemOutputs project system);

  mkFlakeOutputs =
    project:
    let
      systems = project.systems or systemsDefault;
      perSystem = system: mkPerSystemOutputs project system;
    in
    {
      packages = forSystems systems (system: (perSystem system).packages);
      checks = forSystems systems (system: (perSystem system).checks);
    };
}
