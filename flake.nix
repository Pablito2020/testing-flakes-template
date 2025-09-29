{
  description = "Build federated projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mysrc = {
      url = "path:.";    # or some default path
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      pyproject-nix,
      mysrc ? null,
      uv2nix,
      pyproject-build-systems,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      # actualSrc = if mysrc != null then builtins.toPath mysrc else ./.;
      name = "fed_project";


      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = mysrc; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };

      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python312;  # Because nvidia flare doesn't support python313 yet...
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
            ]
          )
      );

    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # pythonSet = pythonSets.${system}.overrideScope editableOverlay;
          # virtualenv = pythonSets.${system}.mkVirtualEnv "${name}-dev" workspace.deps.all;
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              (pythonSets.${system}.mkVirtualEnv name workspace.deps.default)
            ];
            packages = [
              # virtualenv
              # pythonSets.${system}.mkVirtualEnv name workspace.deps.default
              pkgs.uv
            ];
            env = {
              UV_NO_SYNC = "1";
              # UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
            # . ${virtualenv}/bin/activate
          };
        }
      );

      packages = forAllSystems (system: {
        default = pythonSets.${system}.mkVirtualEnv name workspace.deps.default;
      });
    };
}
