#!/bin/bash

# Load machine-local configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/pico-8-config.sh" ]; then
    echo "No pico-8-config.sh found. Create this machine's config first:"
    echo "  cp \"$SCRIPT_DIR/pico-8-config.sh.example\" \"$SCRIPT_DIR/pico-8-config.sh\""
    exit 1
fi
source "$SCRIPT_DIR/pico-8-config.sh"

# Start log monitoring in background
tail -f "$LOG_FILE"