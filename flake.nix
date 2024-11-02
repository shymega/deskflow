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
  };

  nixConfig = {
    extra-trusted-public-keys = ["devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="];
    extra-substituters = ["https://devenv.cachix.org"];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devenv,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          deskflow = pkgs.deskflow.overrideAttrs (oldAttrs: {
            version = "git";
            src = pkgs.lib.cleanSource self;
          });
          default = self.packages.${system}.deskflow;
          devenv-up = self.devShells.${system}.default.config.procfileScript;
        };

        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            (
              {
                pkgs,
                config,
                ...
              }: {
                packages = with pkgs;
                  [
                    curl
                    qt6.qtbase
                    (avahi.override {withLibdnssdCompat = true;})
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
        };
      }
    )
    // {
      overlays.default = final: prev: {inherit (self.packages.${final.system}) deskflow;};
    };
}
