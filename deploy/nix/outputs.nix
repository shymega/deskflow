# SPDX-FileCopyrightText: (C) 2026 Deskflow Developers
# SPDX-License-Identifier: MIT

# Derived from: https://github.com/deskflow/deskflow/pull/10140.
{
  lib ? pkgs.lib,
  pkgs,
  self,
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  inherit (pkgs) deskflow;

  sourceDeskflow = pkgs.deskflow.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "unstable-${self.shortRev or "dirty"}";
      src = lib.cleanSource self;
    }
  );

  deskflowBin =
    if isDarwin then "${deskflow}/Deskflow.app/Contents/MacOS/deskflow" else "${deskflow}/bin/deskflow";

in
{
  packages = {
    inherit deskflow;
    deskflowUnstable = sourceDeskflow;
    default = pkgs.deskflow;
  };

  apps = {
    deskflow = {
      type = "app";
      program = deskflowBin;
    };
    default = {
      type = "app";
      program = deskflowBin;
    };
  };

  devShells.default = pkgs.mkShell {
    inputsFrom = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
      deskflow
    ];
  };
}
