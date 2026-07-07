{
  description = "Don't Repeat Yourself Flakes library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = import ./lib inputs;
      cargoWorkspaceChecks = (lib.mkFlakeOutputs { cargoWorkspace = ./test/fixtures/cargo-workspace; }).checks;
    in
    {
      inherit lib;
      checks = cargoWorkspaceChecks;
    };
}
