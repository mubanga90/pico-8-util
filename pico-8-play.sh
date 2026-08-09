#!/bin/bash
set -e

# Load machine-local configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/pico-8-config.sh" ]; then
    echo "No pico-8-config.sh found. Create this machine's config first:"
    echo "  cp \"$SCRIPT_DIR/pico-8-config.sh.example\" \"$SCRIPT_DIR/pico-8-config.sh\""
    exit 1
fi
source "$SCRIPT_DIR/pico-8-config.sh"

echo -e "${GREEN}Starting PicoCalc...${NC}"

# Ensure we're in the carts directory
cd "$CARTS_DIR" || { echo -e "${RED}Carts directory not found!${NC}"; exit 1; }

# Check if we're in a git repository
if [ -d .git ]; then
    echo -e "${YELLOW}Checking git status...${NC}"

    # Recover from interrupted writes (hard power-off): empty object files
    # are corrupt beyond repair - remove them so fetch can restore them
    EMPTY_OBJS=$(find .git/objects -type f -empty 2>/dev/null | wc -l | tr -d ' ')
    if [ "$EMPTY_OBJS" -gt 0 ]; then
        echo -e "${YELLOW}Found $EMPTY_OBJS corrupt (empty) git object(s) - removing so they can be re-fetched${NC}"
        find .git/objects -type f -empty -delete
    fi

    if ! git remote get-url origin >/dev/null 2>&1; then
        echo -e "${YELLOW}No 'origin' remote configured - skipping sync${NC}"
    elif git fetch origin; then
        # Check if we're behind
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
        BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

        if [ -n "$REMOTE" ]; then
            if [ "$LOCAL" = "$REMOTE" ]; then
                echo -e "${GREEN}Already up to date with origin${NC}"
            elif [ "$LOCAL" = "$BASE" ]; then
                echo -e "${YELLOW}Pulling latest changes...${NC}"
                git merge --ff-only @{u} || echo -e "${RED}Failed to apply remote changes - continuing with local version${NC}"
            elif [ "$REMOTE" = "$BASE" ]; then
                read -p "$(echo -e "${RED}WARNING: Local changes detected! Do you want to reset and pull latest changes? (y/n)${NC} ")" USER_RESET
                if [ "$USER_RESET" = "y" ]; then
                    git reset --hard
                    git merge --ff-only @{u} 2>/dev/null || true
                    echo -e "${GREEN}Changes reset and pulled successfully${NC}"
                else
                    echo -e "${RED}Changes not reset and pulled${NC}"
                fi
            else
                echo -e "${RED}WARNING: Diverged from origin. Manual merge may be needed.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Could not sync with origin (offline or repo problem) - playing local versions${NC}"
    fi
fi

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize log file
echo "PICO-8 log - $(date)" > "$LOG_FILE"

# Start log monitoring in background
tail -f "$LOG_FILE" &
TAIL_PID=$!

# Cleanup function
cleanup() {
    kill "$TAIL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Start PICO-8
echo -e "${GREEN}Launching PICO-8...${NC}"
eval $PICO8_APP "$@" &
PICO8_PID=$!

# Wait for PICO-8 to start
echo "Waiting for PICO-8 to start..."
while ! pgrep -x "pico8" > /dev/null; do
    sleep 0.2
done
echo -e "${GREEN}PICO-8 is running${NC}"

# Wait for PICO-8 to exit
while pgrep -x "pico8" > /dev/null; do
    sleep 1
done

echo -e "${GREEN}PICO-8 session ended${NC}"