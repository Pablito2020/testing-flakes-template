{
  description = "Flake with optional local source override";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    # Do NOT declare `mysrc` here
    mysrc = {
      url = "path:./.";    # or some default path
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mysrc ? null, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      # If mysrc was passed, use it; otherwise default to the flake’s ./.
      actualSrc = if mysrc != null then mysrc else ./.;
    in {
      packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
        pname = "my-package";
        version = "0.1";
        src = actualSrc;
        buildPhase = "echo Building from $src; ls $src";
        installPhase = ''
          mkdir -p $out
          cp -r $src/* $out/
        '';
      };
    };
}
