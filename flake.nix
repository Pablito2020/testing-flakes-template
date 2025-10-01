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
              pyproject-build-systems.overlays.default
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

      packages = forAllSystems (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        hacks = pkgs.callPackage pyproject-nix.build.hacks {};
        pyprojectOverrides = final: prev: {
          antlr4-python3-runtime = prev.antlr4-python3-runtime.overrideAttrs(old: {
            buildInputs = (old.buildInputs or []) ++ final.resolveBuildSystem ( {setuptools = [];});
            });
          pytorch-triton-rocm = prev.pytorch-triton-rocm.overrideAttrs(old: {
            buildInputs = old.buildInputs ++ [
            pkgs.zstd
             pkgs.xz
             pkgs.libz
             pkgs.bzip2
           ];
         });
         # torch = prev.torch.overrideAttrs(old: {
         #   buildInputs = old.buildInputs ++ [
         #     pkgs.zstd
         #     pkgs.xz
         #     pkgs.libz
         #     pkgs.bzip2
         #     pkgs.rocmPackages.rocblas
         #   ];
         # });
         nvidia-cufile-cu12 = prev.nvidia-cufile-cu12.overrideAttrs(old: {
           buildInputs = old.buildInputs ++ [
             pkgs.rdma-core
             pkgs.rocmPackages.rocblas
           ];
         });
         bitsandbytes =  hacks.nixpkgsPrebuilt {
            from = pkgs.python312Packages.bitsandbytes;
         };
         torch = hacks.nixpkgsPrebuilt {
            from = pkgs.python312Packages.torch;
          };
         torchvision = hacks.nixpkgsPrebuilt {
            from = pkgs.python312Packages.torchvision;
          };
          nvidia-cusolver-cu12 = prev.nvidia-cusolver-cu12.overrideAttrs(old: {
           buildInputs = old.buildInputs ++ [
             pkgs.rdma-core
             pkgs.rocmPackages.rocblas
             pkgs.cudatoolkit
           ];
          });
          nvidia-cusparse-cu12 = prev.nvidia-cusparse-cu12.overrideAttrs(old: {
           buildInputs = old.buildInputs ++ [
             pkgs.rdma-core
             pkgs.rocmPackages.rocblas
             pkgs.cudatoolkit
           ];
          });
         # bitsandbytes = prev.bitsandbytes.overrideAttrs(old: {
         #   buildInputs = old.buildInputs ++ [
         #     # pkgs.cudaPackages_11.cudatoolkit
         #    pkgs.cudatoolkit
         #   ];
         # });
        };
        s = pythonSets.${system}.overrideScope pyprojectOverrides;
      in{
        default = s.mkVirtualEnv name workspace.deps.default;
      });
    };
}
