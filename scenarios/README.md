# Linnix Demo Scenarios

Three real-world failure scenarios that Linnix can detect before they cause outages.

## Quick Start

```bash
# Build everything
docker-compose -f docker-compose-demo.yml build

# Start Linnix monitoring
docker-compose -f docker-compose-demo.yml up -d cognitod

# Wait for Linnix to initialize (5 seconds)
sleep 5

# Run all demo scenarios and watch alerts
docker-compose -f docker-compose-demo.yml --profile demo up
```

You'll see Linnix catch all three issues in real-time.

## Scenario 1: Memory Leak Detection

**File:** `memory-leak/leak.py`

**What it does:**
- Allocates 10MB per second without freeing
- Container limited to 200MB
- Will OOM in ~20 seconds if not caught

**What Linnix catches:**
- Memory growth rate exceeds 50MB in 10 seconds
- Alert: "memory_leak_demo" before OOM killer activates

**Run individually:**
```bash
docker-compose -f docker-compose-demo.yml up memory-leak
```

## Scenario 2: Fork Bomb

**File:** `fork-bomb/bomb.sh`

**What it does:**
- Spawns 100 processes at 50 forks/second
- Controlled fork bomb (won't hang system)
- Each child process lives 2 seconds

**What Linnix catches:**
- Fork rate exceeds 10/sec threshold
- Alert: "fork_storm_demo" within 2 seconds
- Also triggers "fork_burst_demo" for 30+ forks in 5 seconds

**Run individually:**
```bash
docker-compose -f docker-compose-demo.yml up fork-bomb
```

## Scenario 3: File Descriptor Exhaustion

**File:** `fd-exhaustion/exhaust.py`

**What it does:**
- Opens files continuously without closing
- Container FD limit: 256
- Opens 10 files/second

**What Linnix catches:**
- FD count exceeds 100 within 10 seconds
- Alert: "fd_leak_demo" ~15 seconds before hitting limit

**Run individually:**
```bash
docker-compose -f docker-compose-demo.yml up fd-exhaustion
```

## Expected Output

When running all scenarios, you should see alerts like:

```
[HIGH] memory_leak_demo: Memory growth rate 60MB in 10s (container: memory-leak)
[HIGH] fork_storm_demo: Fork rate 48/sec detected (container: fork-bomb)
[MEDIUM] fork_burst_demo: 35 forks in 5 seconds (container: fork-bomb)
[HIGH] fd_leak_demo: 120 open FDs, approaching limit 256 (container: fd-exhaustion)
```

## Viewing Alerts

**Option 1: CLI (real-time stream)**
```bash
docker-compose -f docker-compose-demo.yml run --rm linnix-cli
```

**Option 2: HTTP API**
```bash
curl http://localhost:3000/alerts
```

**Option 3: Prometheus metrics**
```bash
curl http://localhost:3000/metrics | grep linnix_alerts
```

## Cleanup

```bash
docker-compose -f docker-compose-demo.yml down
docker-compose -f docker-compose-demo.yml --profile demo down
```

## Customizing Scenarios

Edit `demo-rules.yaml` to adjust:
- Detection thresholds
- Alert cooldown periods
- Severity levels

Modify scenario scripts to:
- Change leak rates
- Adjust fork speeds
- Control FD exhaustion timing
