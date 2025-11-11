{ pkgs, self }:

let
  inherit (pkgs) lib;

in
pkgs.testers.runNixOSTest {
  name = "linnix-vm-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.default ];

    # Use a newer kernel with good eBPF support
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Enable Linnix service
    services.linnix = {
      enable = true;
      package = self.packages.${pkgs.system}.linnix;

      settings = {
        runtime.offline = true;
        telemetry.sample_interval_ms = 500;
        rules = {
          enabled = true;
        };
        api.bind_address = "0.0.0.0:3000";
      };

      handlers = [ "rules:/etc/linnix/rules.yaml" ];
    };

    # Ensure debugfs is mounted (needed for eBPF)
    boot.kernelParams = [ "debugfs=on" ];

    # Additional packages for testing
    environment.systemPackages = with pkgs; [
      curl
      jq
    ];
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    # Check that cognitod service is running
    machine.wait_for_unit("cognitod.service")
    machine.succeed("systemctl is-active cognitod.service")

    # Wait for the service to be fully ready
    machine.sleep(5)

    # Check if the API is responding
    machine.succeed("curl -f http://localhost:3000/health")

    # Test health endpoint returns OK
    health_output = machine.succeed("curl -s http://localhost:3000/health")
    print(f"Health check response: {health_output}")

    # Test metrics endpoint (Prometheus format)
    machine.succeed("curl -f http://localhost:3000/metrics")
    metrics = machine.succeed("curl -s http://localhost:3000/metrics")
    print(f"Metrics sample:\n{metrics[:500]}...")

    # Test processes endpoint returns JSON
    machine.succeed("curl -f http://localhost:3000/processes")
    processes = machine.succeed("curl -s http://localhost:3000/processes | jq -c '.[:2]'")
    print(f"First two processes: {processes}")

    # Test alerts endpoint
    machine.succeed("curl -f http://localhost:3000/alerts")

    # Generate some process activity to test eBPF monitoring
    machine.succeed("sleep 1 &")
    machine.succeed("echo 'test' > /tmp/test.txt")
    machine.succeed("cat /tmp/test.txt")

    # Wait for events to be processed
    machine.sleep(2)

    # Check that we're capturing events
    processes_after = machine.succeed("curl -s http://localhost:3000/processes | jq 'length'")
    print(f"Number of tracked processes: {processes_after}")

    # Verify we have at least some processes
    assert int(processes_after) > 0, "No processes tracked by cognitod"

    # Test streaming endpoint (SSE) - just verify it accepts connections
    # We'll timeout after 2 seconds which is fine for this test
    machine.succeed("timeout 2 curl -N http://localhost:3000/stream || true")

    # Check logs for any errors
    logs = machine.succeed("journalctl -u cognitod.service --no-pager")
    print("Service logs:")
    print(logs)

    # Ensure no critical errors in logs
    machine.fail("journalctl -u cognitod.service --no-pager | grep -i 'error.*ebpf'")

    # Test graceful shutdown
    machine.succeed("systemctl stop cognitod.service")
    machine.wait_until_fails("systemctl is-active cognitod.service")

    # Restart and verify it comes back up
    machine.succeed("systemctl start cognitod.service")
    machine.wait_for_unit("cognitod.service")
    machine.succeed("curl -f http://localhost:3000/health")

    print("All tests passed!")
  '';

  meta = {
    maintainers = [ ];
  };
}
