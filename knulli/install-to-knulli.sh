#!/bin/bash
set -e

# Installs the PICO-8 sync wrapper onto a KNULLI device over SSH.
#
# Usage: ./install-to-knulli.sh [user@host]
#   default host: root@knulli.local (default KNULLI SSH password: linux)
#
# Prerequisite: native PICO-8 installed on the device per
# https://knulli.org/systems/pico-8/ (binaries in /userdata/bios/pico-8/).
# Safe to re-run: it only moves the real binary aside once, then just
# refreshes the wrapper.

HOST="${1:-root@knulli.local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing PICO-8 sync wrapper to $HOST (default password: linux)"

ssh "$HOST" '
    set -e
    cd /userdata/bios/pico-8 2>/dev/null || {
        echo "ERROR: /userdata/bios/pico-8 not found."
        echo "Install the native PICO-8 binaries first: https://knulli.org/systems/pico-8/"
        exit 1
    }
    cat > pico8.wrapper

    # First install: move the real ELF binary aside
    if [ ! -e pico8.real ] && [ -f pico8 ] && head -c 4 pico8 | grep -q ELF; then
        mv pico8 pico8.real
    fi

    if [ ! -e pico8.real ]; then
        rm -f pico8.wrapper
        echo "ERROR: real pico8 binary not found in /userdata/bios/pico-8."
        echo "Install the native PICO-8 binaries first: https://knulli.org/systems/pico-8/"
        exit 1
    fi

    mv pico8.wrapper pico8
    chmod +x pico8 pico8.real
    mkdir -p /userdata/roms/pico8/debug
    echo "Wrapper installed - real binary kept as pico8.real"
' < "$SCRIPT_DIR/pico8"

printf "GitHub token for the private carts repo (Enter to skip/keep existing): "
read -rs TOKEN
echo
if [ -n "$TOKEN" ]; then
    printf '%s' "$TOKEN" | ssh "$HOST" 'umask 077; cat > /userdata/system/pico8-github-token'
    echo "Token stored on the device at /userdata/system/pico8-github-token"
fi

echo "Done. Launch Splore or any cart on the device - it will sync first."
