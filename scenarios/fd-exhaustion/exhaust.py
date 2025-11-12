#!/usr/bin/env python3
"""
File descriptor exhaustion scenario for Linnix demo.
Opens files without closing them until hitting ulimit.
"""
import os
import sys
import time
import tempfile

def exhaust_fds():
    """Open files continuously without closing them."""
    open_files = []
    iteration = 0

    print("Starting FD exhaustion scenario...", flush=True)
    print(f"PID: {os.getpid()}", flush=True)

    # Get current FD limit
    import resource
    soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
    print(f"FD limit: {soft} (soft), {hard} (hard)", flush=True)

    try:
        while True:
            # Open a temp file and keep it open
            f = tempfile.TemporaryFile(mode='w+')
            open_files.append(f)
            iteration += 1

            if iteration % 50 == 0:
                print(f"Opened {iteration} files (approaching limit: {soft})...", flush=True)

            time.sleep(0.1)

    except OSError as e:
        print(f"\nFailed to open more files after {iteration} attempts: {e}", flush=True)
        print(f"Hit FD limit at {iteration} open files", flush=True)
        sys.exit(1)

if __name__ == "__main__":
    try:
        exhaust_fds()
    except KeyboardInterrupt:
        print("\nFD exhaustion stopped.", flush=True)
        sys.exit(0)
