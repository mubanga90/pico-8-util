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
                echo -e "${YELLOW}Unpushed local commits detected, pushing...${NC}"
                git push || echo -e "${RED}Push failed - will retry after PICO-8 exits${NC}"
            else
                echo -e "${RED}WARNING: Diverged from origin. Manual merge may be needed.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Could not sync with origin (offline or repo problem) - changes will be committed locally${NC}"
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

# Wait for PICO-8 to start (give it a moment)
echo "Waiting for PICO-8 to start..."
sleep 1

# Check if the PID is valid and still running
if kill -0 $PICO8_PID 2>/dev/null; then
    echo -e "${GREEN}PICO-8 is running (PID: $PICO8_PID)${NC}"
    # Wait for PICO-8 to exit using the captured PID
    wait $PICO8_PID 2>/dev/null
else
    echo -e "${YELLOW}Launcher exited, monitoring process by name...${NC}"
    # Fallback for macOS that uses open to launch PICO-8
    while pgrep -x "pico8" > /dev/null; do
        sleep 1
    done
fi

echo -e "${YELLOW}PICO-8 has exited${NC}"

# Git commit and push if there are changes
if [ -d .git ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}Changes detected, git status:${NC}"
        git add -A
        git status

        # Auto-generate commit message with timestamp
        COMMIT_MSG="Auto-save from PicoCalc - $(date '+%Y-%m-%d %H:%M:%S')"

        read -p "Enter commit message (or press Enter for auto, press r to reset the changes or press q to quit): " USER_MSG
        if [ "$USER_MSG" = "r" ]; then
            git reset --hard
            echo -e "${GREEN}Changes reset successfully${NC}"
            exit 0
        elif [ "$USER_MSG" = "q" ]; then
            echo -e "${RED}Quitting...${NC}"
            exit 0
        fi
        [ -n "$USER_MSG" ] && COMMIT_MSG="$USER_MSG"

        git commit -m "$COMMIT_MSG"
    else
        echo -e "${GREEN}No changes detected${NC}"
    fi

    # Push anything unpushed - from this session or a previous offline one
    if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        AHEAD=$(git rev-list --count '@{u}..@')
        if [ "$AHEAD" -gt 0 ]; then
            echo -e "${YELLOW}Pushing $AHEAD commit(s)...${NC}"
            if git push; then
                echo -e "${GREEN}Changes pushed successfully${NC}"
            else
                echo -e "${RED}Push failed (no internet?). Commits are saved locally and will be pushed on the next run.${NC}"
            fi
        fi
    fi
fi

echo -e "${GREEN}PICO-8 session ended${NC}"