#!/bin/bash
# Controlled fork bomb for Linnix demo
# Spawns processes at high rate without completely hanging system

echo "Starting fork bomb scenario..."
echo "PID: $$"

# Counter to limit total forks
count=0
max_forks=100

fork_worker() {
    local id=$1
    echo "Forked process $id (PID: $$)"
    sleep 2
    exit 0
}

# Spawn processes rapidly
while [ $count -lt $max_forks ]; do
    fork_worker $count &
    ((count++))

    # Print every 10 forks
    if [ $((count % 10)) -eq 0 ]; then
        echo "Spawned $count processes..."
    fi

    # Very short sleep = high fork rate
    sleep 0.02  # 50 forks/sec
done

echo "Fork bomb complete. Waiting for children to exit..."
wait
echo "All children exited."
