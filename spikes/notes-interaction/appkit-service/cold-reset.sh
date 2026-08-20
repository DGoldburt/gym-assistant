#!/bin/bash

set -euo pipefail

process_name="GymAssistantService"

if pgrep -x "$process_name" >/dev/null; then
    pkill -TERM -x "$process_name"

    for _ in 1 2 3 4 5; do
        if ! pgrep -x "$process_name" >/dev/null; then
            break
        fi
        sleep 0.1
    done
fi

if pgrep -x "$process_name" >/dev/null; then
    echo "Cold reset failed: $process_name is still running." >&2
    exit 1
fi

echo "Cold reset ready: Notes remains open and $process_name is not resident."
