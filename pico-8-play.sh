#!/bin/bash
set -e

# Load shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pico-8-config.sh"

echo -e "${GREEN}Starting PicoCalc...${NC}"

# Ensure we're in the carts directory
cd "$CARTS_DIR" || { echo -e "${RED}Carts directory not found!${NC}"; exit 1; }

# Check if we're in a git repository
if [ -d .git ]; then
    echo -e "${YELLOW}Checking git status...${NC}"
    
    # Fetch latest changes
    git fetch origin
    
    # Check if we're behind
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
    BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")
    
    if [ -n "$REMOTE" ]; then
        if [ "$LOCAL" = "$REMOTE" ]; then
            echo -e "${GREEN}Already up to date with origin${NC}"
        elif [ "$LOCAL" = "$BASE" ]; then
            echo -e "${YELLOW}Pulling latest changes...${NC}"
            git pull
        elif [ "$REMOTE" = "$BASE" ]; then
            read -p "${RED}WARNING: Local changes detected! Do you want to reset and pull latest changes? (y/n)${NC}" USER_RESET
            if [ "$USER_RESET" = "y" ]; then
                git reset --hard
                git pull
                echo -e "${GREEN}Changes reset and pulled successfully${NC}"
            else
                echo -e "${RED}Changes not reset and pulled${NC}"
            fi
        else
            echo -e "${RED}WARNING: Diverged from origin. Manual merge may be needed.${NC}"
        fi
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