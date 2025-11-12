#!/usr/bin/env python3
"""
Memory leak scenario for Linnix demo.
Leaks ~10MB per second until OOM or killed.
"""
import time
import sys

def leak_memory():
    """Continuously allocate memory without freeing it."""
    leaked_data = []
    iteration = 0

    print("Starting memory leak scenario...", flush=True)
    print(f"PID: {os.getpid()}", flush=True)

    while True:
        # Allocate 10MB of data
        chunk = 'X' * (10 * 1024 * 1024)
        leaked_data.append(chunk)
        iteration += 1

        if iteration % 5 == 0:
            print(f"Leaked {iteration * 10}MB so far...", flush=True)

        time.sleep(1)

if __name__ == "__main__":
    import os
    try:
        leak_memory()
    except KeyboardInterrupt:
        print("\nMemory leak stopped.", flush=True)
        sys.exit(0)
    except MemoryError:
        print("\nOOM: Out of memory!", flush=True)
        sys.exit(1)
