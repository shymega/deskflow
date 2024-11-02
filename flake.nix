# SPDX-FileCopyrightText: 2025 The Deskflow Developers
#
# SPDX-License-Identifier: MIT
{
  description = "Nix Flake for Deskflow";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    systems.url = "github:nix-systems/triplet";
  };

  nixConfig = {
    extra-trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    extra-substituters = [ "https://devenv.cachix.org" ];
  };

  outputs =
    inputs:
    let
      inherit (inputs) self;

      forEachSystem =
        let
          inherit (inputs) systems;
          genPkgs =
            system:
            let
              inherit (inputs) nixpkgs;
            in
            import nixpkgs {
              inherit system;
              overlays = [
                (_: prev: {
                  deskflow = prev.deskflow.overrideAttrs (oldAttrs: {
                    version = "git";
                    src = prev.lib.cleanSource self;
                    postPatch = ''
                      substituteInPlace deploy/linux/deploy.cmake \
                        --replace-fail 'message(FATAL_ERROR "Unable to read file /etc/os-release")' 'set(RELEASE_FILE_CONTENTS "")'
                    '';
                  });
                })
              ];
            };
          inherit (inputs.nixpkgs.lib) genAttrs;
        in
        f: genAttrs (import systems) (system: f (genPkgs system));
    in
    {
      packages = forEachSystem (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        {
          inherit (pkgs) deskflow;
          default = self.packages.${system}.deskflow;
          devenv-up = self.devShells.${system}.default.config.procfileScript;
        }
      );

      devShells.default = forEachSystem (
        pkgs:
        let
          inherit (inputs) devenv;
        in
        devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            (
              {
                pkgs,
                config,
                ...
              }:
              {
                packages =
                  with pkgs;
                  [
                    curl
                    qt6.qtbase
                    (avahi.override { withLibdnssdCompat = true; })
                    openssl
                    pugixml
                    python3
                    libnotify
                    gtest
                    lerc
                    cli11
                    tomlplusplus
                    pkg-config
                    cmake
                    qt6.qttools
                  ]
                  ++ (with pkgs.xorg; [
                    libX11
                    libXext
                    libXtst
                    libXinerama
                    libXrandr
                    libXdmcp
                    libxkbfile
                    libICE
                    libSM
                  ]);
                languages = {
                  c.enable = true;
                  cplusplus.enable = true;
                  nix.enable = true;
                  shell.enable = true;
                };
                devcontainer.enable = true;
              }
            )
          ];
        }
      );
      overlays.default = final: _: self.packages.${final.stdenv.hostPlatform.system} or { };
    };
}
