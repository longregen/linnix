{ lib
, stdenv
, rustPlatform
, rust-bin
, pkg-config
, clang
, llvm
, libelf
, zlib
, openssl
, makeWrapper
, fetchFromGitHub
}:

let
  # Nightly Rust for eBPF compilation
  nightlyRust = rust-bin.nightly."2024-12-10".minimal.override {
    extensions = [ "rust-src" ];
    targets = [ "bpfel-unknown-none" ];
  };

  # Stable Rust for userspace
  stableRust = rust-bin.stable.latest.default;

  # Build eBPF programs separately
  ebpfPrograms = stdenv.mkDerivation {
    pname = "linnix-ebpf";
    version = "0.1.0";

    src = ../linnix-ai-ebpf;

    nativeBuildInputs = [
      nightlyRust
      clang
      llvm
      pkg-config
    ];

    buildInputs = [
      libelf
      zlib
    ];

    buildPhase = ''
      export LIBCLANG_PATH="${llvm}/lib"
      export CARGO_HOME=$(mktemp -d)

      cd linnix-ai-ebpf-ebpf
      cargo build --release --target=bpfel-unknown-none
    '';

    installPhase = ''
      mkdir -p $out
      cp target/bpfel-unknown-none/release/linnix-ai-ebpf-ebpf $out/
    '';
  };

in
rustPlatform.buildRustPackage rec {
  pname = "linnix";
  version = "0.1.0";

  src = lib.cleanSource ../.;

  cargoLock = {
    lockFile = ../Cargo.lock;
    outputHashes = {
      # Git dependency from https://github.com/aya-rs/aya
      # Hash obtained from build output
      "aya-0.13.1" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    clang
    llvm
    makeWrapper
    stableRust
  ];

  buildInputs = [
    libelf
    zlib
    openssl
  ];

  # Skip tests that require root/eBPF
  doCheck = false;

  preBuild = ''
    export LIBCLANG_PATH="${llvm}/lib"
    export LINNIX_BPF_PATH="${ebpfPrograms}/linnix-ai-ebpf-ebpf"
  '';

  # Build only the main packages
  cargoBuildFlags = [
    "-p" "cognitod"
    "-p" "linnix-cli"
    "-p" "linnix-reasoner"
  ];

  postInstall = ''
    # Install eBPF programs
    mkdir -p $out/share/linnix
    cp ${ebpfPrograms}/linnix-ai-ebpf-ebpf $out/share/linnix/

    # Install configuration files
    mkdir -p $out/etc/linnix
    cp configs/linnix.toml $out/etc/linnix/linnix.toml.example
    cp configs/rules.yaml $out/etc/linnix/

    # Wrap binaries with default eBPF path
    for bin in cognitod; do
      wrapProgram $out/bin/$bin \
        --set-default LINNIX_BPF_PATH "$out/share/linnix/linnix-ai-ebpf-ebpf"
    done
  '';

  meta = with lib; {
    description = "eBPF-powered Linux observability with optional AI incident detection";
    homepage = "https://github.com/linnix-os/linnix";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "cognitod";
  };
}
