#!/bin/bash

# Load shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pico-8-config.sh"

# Start log monitoring in background
tail -f "$LOG_FILE" &
TAIL_PID=$!

# Cleanup function
cleanup() {
    kill "$TAIL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM