{
  description = "Linnix - eBPF-powered Linux observability with optional AI incident detection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        linnix = pkgs.callPackage ./nix/package.nix { };
      in
      {
        packages = {
          default = linnix;
          linnix = linnix;
        };

        apps = {
          default = {
            type = "app";
            program = "${linnix}/bin/cognitod";
          };
          cognitod = {
            type = "app";
            program = "${linnix}/bin/cognitod";
          };
          linnix-cli = {
            type = "app";
            program = "${linnix}/bin/linnix-cli";
          };
          linnix-reasoner = {
            type = "app";
            program = "${linnix}/bin/linnix-reasoner";
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Rust toolchain with nightly for eBPF
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
            rust-bin.nightly."2024-12-10".minimal

            # eBPF build tools
            clang
            llvm
            llvmPackages.libclang
            libelf
            pkg-config

            # Development tools
            cargo-watch
            cargo-edit

            # Runtime dependencies
            zlib
            openssl
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          shellHook = ''
            echo "Linnix development environment"
            echo "Run 'cargo xtask build-ebpf' to build eBPF programs"
            echo "Run 'cargo build --release' to build userspace binaries"
          '';
        };
      }
    ) // {
      # NixOS module (system-independent)
      nixosModules.default = import ./nix/module.nix;
      nixosModules.linnix = import ./nix/module.nix;

      # NixOS VM test (for x86_64-linux only)
      checks.x86_64-linux = {
        vm-test = import ./nix/vm-test.nix {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          inherit self;
        };
      };
    };
}
