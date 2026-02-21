#!/bin/bash

# Load shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pico-8-config.sh"

# Start log monitoring in background
tail -f "$LOG_FILE"