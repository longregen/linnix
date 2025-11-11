# Nix Flake for Linnix

This directory contains Nix packaging and NixOS integration for Linnix.

## Quick Start

### Install via Nix Flakes

```bash
# Try it without installing
nix run github:linnix-os/linnix

# Install it
nix profile install github:linnix-os/linnix
```

### Build from source

```bash
# Clone the repo
git clone https://github.com/linnix-os/linnix.git
cd linnix

# Build the package
nix build

# Run it
./result/bin/cognitod --help
```

## NixOS Module

### Basic Configuration

Add to your `configuration.nix`:

```nix
{
  inputs.linnix.url = "github:linnix-os/linnix";

  outputs = { self, nixpkgs, linnix }: {
    nixosConfigurations.yourHost = nixpkgs.lib.nixosSystem {
      modules = [
        linnix.nixosModules.default
        {
          services.linnix = {
            enable = true;
            settings = {
              api.bind_address = "0.0.0.0:3000";
              telemetry.sample_interval_ms = 1000;
            };
            handlers = [ "rules:/etc/linnix/rules.yaml" ];
          };
        }
      ];
    };
  };
}
```

### Advanced Configuration

```nix
{
  services.linnix = {
    enable = true;

    # Custom package (e.g., for development)
    package = pkgs.linnix.overrideAttrs (old: {
      src = /path/to/linnix/source;
    });

    # Full configuration
    settings = {
      runtime = {
        offline = false;
      };

      telemetry = {
        sample_interval_ms = 500;
      };

      rules = {
        enabled = true;
        config_path = "/etc/linnix/rules.yaml";
      };

      api = {
        bind_address = "127.0.0.1:3000";
      };

      llm = {
        endpoint = "http://localhost:8090/v1/chat/completions";
        model = "qwen2.5-7b";
        timeout_secs = 120;
      };
    };

    # Custom rules file
    rulesFile = ./my-rules.yaml;

    # Enable handlers
    handlers = [
      "rules:/etc/linnix/rules.yaml"
      # "llm:config.toml"  # Uncomment if using LLM
    ];

    # Open firewall for API
    openFirewall = true;
  };
}
```

## Development

### Enter development shell

```bash
nix develop

# Or with direnv
echo "use flake" > .envrc
direnv allow
```

The development shell includes:
- Rust stable and nightly toolchains
- eBPF build tools (clang, llvm, bpf-linker)
- Development utilities (cargo-watch, rust-analyzer)

### Building eBPF programs

```bash
nix develop
cargo xtask build-ebpf
```

## Testing

### Run VM tests

```bash
# Run the full NixOS VM test
nix flake check

# Or specifically run the VM test
nix build .#checks.x86_64-linux.vm-test
```

The VM test will:
1. Start a NixOS VM with Linnix enabled
2. Verify the service starts correctly
3. Test API endpoints
4. Verify eBPF monitoring is working
5. Test service restarts

### Interactive VM testing

```bash
# Build and run the VM interactively
nix build .#checks.x86_64-linux.vm-test.driverInteractive
./result/bin/nixos-test-driver

# Inside the test driver
>>> machine.shell_interact()
```

## Files

- **flake.nix** - Main flake definition with outputs
- **package.nix** - Nix package derivation for building Linnix
- **module.nix** - NixOS module for system integration
- **vm-test.nix** - Automated VM integration tests

## Requirements

- Linux kernel 5.8+ with BTF support
- Nix with flakes enabled
- For NixOS module: NixOS 23.05 or later

## Troubleshooting

### eBPF permissions

Linnix requires elevated privileges for eBPF. The NixOS module runs the service as root with appropriate capabilities.

### BTF support

Check if your kernel has BTF enabled:

```bash
ls /sys/kernel/btf/vmlinux
```

If not present, you may need to enable BTF in your kernel configuration.

### Build issues

If you encounter build issues:

```bash
# Clear the build cache
nix-store --verify --check-contents

# Rebuild with verbose output
nix build --print-build-logs
```

## Contributing

When modifying the Nix packaging:

1. Test locally: `nix build`
2. Run checks: `nix flake check`
3. Update Cargo.lock hash in package.nix if dependencies change
4. Test the NixOS module with the VM test

## License

Same as Linnix: Apache 2.0
