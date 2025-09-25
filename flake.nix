{
  description = "Playing with templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" ];
    in
    {
      packages = builtins.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          myProject = { src }:
            pkgs.python3.withPackages (ps: with ps; [
              # whatever dependencies
            ]);
        });
    };
}

