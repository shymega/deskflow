# SPDX-FileCopyrightText: (C) 2026 Deskflow Developers
# SPDX-License-Identifier: MIT
{
  description = "Nix Flake for Deskflow";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=pull/535029/merge";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs) self;

      forEachSystem =
        let
          supportedSystems = [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-darwin"
            "x86_64-linux"
          ];
          genPkgs =
            system:
            let
              inherit (inputs) nixpkgs;
            in
            import nixpkgs {
              inherit system;
            }
            // nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
              config.allowDeprecatedx86_64Darwin = true;
            };
          inherit (inputs.nixpkgs.lib) genAttrs;
        in
        f: genAttrs supportedSystems (system: f (genPkgs system));
    in
    let
      outputsFor = pkgs: import ./deploy/nix/outputs.nix { inherit pkgs self; };
    in
    {
      packages = forEachSystem (pkgs: (outputsFor pkgs).packages);
      apps = forEachSystem (pkgs: (outputsFor pkgs).apps);
      devShells = forEachSystem (pkgs: (outputsFor pkgs).devShells);
      overlays.default = final: _: self.packages.${final.stdenv.hostPlatform.system} or { };
    };
}
