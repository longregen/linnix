{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.linnix;

  configFormat = pkgs.formats.toml { };

  configFile = if cfg.configFile != null
    then cfg.configFile
    else configFormat.generate "linnix.toml" cfg.settings;

in {
  options.services.linnix = {
    enable = mkEnableOption "Linnix eBPF-powered Linux observability daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.linnix;
      defaultText = literalExpression "pkgs.linnix";
      description = "The linnix package to use.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to linnix configuration file.
        If null, a configuration file will be generated from settings.
      '';
    };

    settings = mkOption {
      type = configFormat.type;
      default = { };
      description = ''
        Linnix configuration settings. See linnix.toml.example for options.
      '';
      example = literalExpression ''
        {
          runtime.offline = false;
          telemetry.sample_interval_ms = 1000;
          rules = {
            enabled = true;
            config_path = "/etc/linnix/rules.yaml";
          };
          api.bind_address = "127.0.0.1:3000";
        }
      '';
    };

    rulesFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to rules.yaml file. If null, the default rules from the package will be used.
      '';
    };

    handlers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of handlers to enable. Format: "type:path" or "type".
        Example: [ "rules:/etc/linnix/rules.yaml" "llm:config.toml" ]
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open the firewall for the Linnix API port.
        The port is determined from settings.api.bind_address or defaults to 3000.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Set default settings if not provided
    services.linnix.settings = mkDefault {
      runtime.offline = false;
      telemetry.sample_interval_ms = 1000;
      rules = {
        enabled = cfg.handlers != [ ] || cfg.rulesFile != null;
        config_path = if cfg.rulesFile != null
          then cfg.rulesFile
          else "${cfg.package}/etc/linnix/rules.yaml";
      };
      api.bind_address = "127.0.0.1:3000";
    };

    # Ensure kernel supports eBPF
    assertions = [
      {
        assertion = config.boot.kernelPackages.kernel.version >= "5.8";
        message = "Linnix requires Linux kernel 5.8 or higher with BTF support";
      }
    ];

    # Enable BTF (BPF Type Format)
    boot.kernel.sysctl."kernel.bpf_stats_enabled" = mkDefault 1;

    # Kernel features needed for eBPF
    boot.kernelParams = [ "debugfs=on" ];

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d /var/lib/linnix 0755 linnix linnix -"
      "d /etc/linnix 0755 root root -"
    ];

    # Create linnix user and group
    users.users.linnix = {
      isSystemUser = true;
      group = "linnix";
      description = "Linnix daemon user";
    };

    users.groups.linnix = { };

    # Systemd service
    systemd.services.cognitod = {
      description = "Linnix eBPF Observability Daemon";
      documentation = [ "https://github.com/linnix-os/linnix" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        RUST_LOG = mkDefault "info";
        LINNIX_CONFIG = configFile;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = let
          handlerArgs = concatMapStringsSep " " (h: "--handler ${h}") cfg.handlers;
        in "${cfg.package}/bin/cognitod --config ${configFile} ${handlerArgs}";

        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening (while allowing eBPF)
        # Note: eBPF requires CAP_BPF, CAP_PERFMON, or CAP_SYS_ADMIN
        User = "root"; # eBPF requires elevated privileges
        Group = "root";

        # Capabilities
        AmbientCapabilities = [ "CAP_BPF" "CAP_PERFMON" "CAP_SYS_RESOURCE" ];
        CapabilityBoundingSet = [ "CAP_BPF" "CAP_PERFMON" "CAP_SYS_RESOURCE" ];

        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/linnix" ];

        # Resource limits
        LimitNOFILE = 65536;
        LimitMEMLOCK = "infinity"; # Required for eBPF maps
      };
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = let
        bindAddress = cfg.settings.api.bind_address or "127.0.0.1:3000";
        port = toInt (last (splitString ":" bindAddress));
      in [ port ];
    };

    # Add linnix package to system packages
    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = [ ];
}
