{
  description = "Linnix - eBPF-powered Linux observability platform with AI incident detection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchains
        stableRust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "clippy" ];
        };

        nightlyRust = pkgs.rust-bin.nightly."2024-12-10".default.override {
          extensions = [ "rust-src" "llvm-tools-preview" ];
        };

        # Crane library for building Rust packages
        craneLib = (crane.mkLib pkgs).overrideToolchain stableRust;
        craneLibNightly = (crane.mkLib pkgs).overrideToolchain nightlyRust;

        # Common arguments for crane
        src = craneLib.cleanCargoSource ./.;

        commonArgs = {
          inherit src;
          strictDeps = true;

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
          ];
        };

        # Build eBPF components
        linnix-ebpf = craneLibNightly.buildPackage (commonArgs // {
          pname = "linnix-ebpf";
          version = "0.1.0";

          cargoExtraArgs = "--package linnix-ai-ebpf-ebpf --target bpfel-unknown-none -Z build-std=core";

          nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
            pkgs.bpf-linker
            pkgs.llvmPackages_19.clang
            pkgs.llvmPackages_19.llvm
          ];

          # Don't run tests for eBPF
          doCheck = false;

          CARGO_BUILD_TARGET = "bpfel-unknown-none";
          RUSTUP_TOOLCHAIN = "nightly-2024-12-10";
          LLVM_SYS_191_PREFIX = "${pkgs.llvmPackages_19.llvm.dev}";

          installPhaseCommand = ''
            mkdir -p $out/lib
            if [ -d "target/bpfel-unknown-none/release" ]; then
              cp -r target/bpfel-unknown-none/release/linnix-ai-ebpf-ebpf $out/lib/ 2>/dev/null || true
              cp -r target/bpfel-unknown-none/release/rss_trace $out/lib/ 2>/dev/null || true
            fi
          '';
        });

        # Build main Linnix packages
        # First, build dependencies only
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # Build the main package
        linnix = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;

          pname = "linnix";
          version = "0.1.0";

          cargoExtraArgs = "--package cognitod --package linnix-cli --package linnix-reasoner";

          # Copy eBPF artifacts before build
          preBuild = ''
            mkdir -p target/bpfel-unknown-none/release
            if [ -d "${linnix-ebpf}/lib" ]; then
              cp -r ${linnix-ebpf}/lib/* target/bpfel-unknown-none/release/ 2>/dev/null || true
            fi
          '';

          # Run tests excluding eBPF
          cargoTestExtraArgs = "--workspace --exclude linnix-ai-ebpf-ebpf";
        });

      in
      {
        checks = {
          inherit linnix;
        };

        packages = {
          default = linnix;
          inherit linnix linnix-ebpf;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = linnix;
          exePath = "/bin/cognitod";
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ linnix ];

          buildInputs = with pkgs; [
            stableRust
            nightlyRust
            bpf-linker
            cargo-nextest
            cargo-deny
            cargo-watch
            llvmPackages_19.clang
            llvmPackages_19.llvm
          ];

          shellHook = ''
            echo "Linnix development environment"
            echo "Rust stable: $(rustc --version)"
            echo ""
            echo "Commands:"
            echo "  cargo build              - Build main packages"
            echo "  cargo xtask build-ebpf   - Build eBPF programs"
            echo "  cargo nextest run        - Run tests"
            echo "  nix build                - Build with Nix"
          '';

          LLVM_SYS_191_PREFIX = "${pkgs.llvmPackages_19.llvm.dev}";
        };
      }
    );
}
