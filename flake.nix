{
  description = "Flake that builds something from a src";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, asrc ? null, ... }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    actualSrc = if asrc != null then asrc else ./.;
  in {
    packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
      name = "my-custom-build";
      src = actualSrc;
      buildPhase = "echo Building from $src; ls $src";
      installPhase = ''
        mkdir -p $out
        cp -r $src/* $out/
      '';
    };
  };
}
#
# {
#   description =
#     "Some configurable flake";
#   inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#   inputs.flake-utils.url = "github:numtide/flake-utils";
#   inputs.configurable-flakes.url = "github:sents/configurable-flakes";
#
#   outputs = inputs@{ self, nixpkgs, flake-utils, configurable-flakes }:
#     let
#       lib = nixpkgs.lib;
#     in
#     configurable-flakes.lib.configurableFlake inputs
#       {
#         options = {
#           systems = lib.mkOption {
#             type = with lib.types; listOf (enum flake-utils.lib.allSystems);
#             default = [ "aarch64-linux" "x86_64-linux"];
#           };
#           debug = lib.mkEnableOption "debug";
#         };
#       }
#       ({ config, ... }:
#         flake-utils.lib.eachSystem config.systems (system:
#           let
#             pkgs = nixpkgs.legacyPackages.${system};
#             packages = import ./default.nix { inherit pkgs;
#                                               debug = config.debug;
#                                             };
#           in
#           { packages = packages // { default = packages.foo; }; }));
# }
# {
#   description = "Demo: configurable-flakes example";
#
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     configurable-flakes.url = "github:sents/configurable-flakes";
#   };
#
#   outputs = { self, nixpkgs, configurable-flakes, ... }@inputs:
#     let
#       lib = nixpkgs.lib;
#       cf = configurable-flakes.lib;
#     in
#     cf.configurableFlake inputs 
#     {
#         options = {
#           systems = lib.mkOption {
#             type = with lib.types; listOf (enum flake-utils.lib.allSystems);
#             default = [ "aarch64-linux" "x86_64-linux"];
#           };
#           enableHello = lib.mkEnableOption "enableHello";
#         };
#     }
#     (config: inputs: {
#       packages = rec {
#         mypkg = let
#           pkgs = inputs.nixpkgs.legacyPackages."${config.system}";
#         in
#         pkgs.stdenv.mkDerivation {
#           pname = "mypkg";
#           version = "0.1.0";
#           src = ./src;
#           buildInputs = [ pkgs.gcc ];  # or whatever C compiler
#
#           buildPhase = ''
#             echo "Hi!" > hello
#             if test ${toString config.enableHello} = "true"; then
#               echo "enabled" > hello
#             fi
#           '';
#
#           installPhase = ''
#             mkdir -p $out/bin
#             cp hello $out/bin/
#           '';
#         };
#       };
#
#       # defaultPackage = config.system: packages.mypkg;
#     });
# }
