# PICO-8 Utilities

Couple of scripts to make development on PICO-8 easier.

## Common Setup

1. Clone this repository
2. Configure the correct paths in `pico-8-config.sh`
   - Default for macOS: 
   ```bash
   PICO8_APP="open /Applications/PICO-8.app"
   CARTS_DIR="$HOME/Library/Application Support/pico-8/carts/"
   LOG_FILE="$CARTS_DIR/debug/log.txt"
   ```
   - Default for Linux: 
   ```bash
   PICO8_APP="pico8"
   CARTS_DIR="$HOME/.lexaloffle/pico-8/carts"
   LOG_FILE="$CARTS_DIR/debug/log.txt"
   ```
3. Make your cart directory a git repository
4. Create `debug/log.txt` file in your cart directory, and add it to .gitignore
5. Run 
    ```bash
    chmod +x pico-8-config.sh pico-8-dev.sh pico-8-play.sh pico-8-log.sh
   ```
   to make the scripts executable.
6. Add the scripts the scripts you want to use your shell aliases (in your `.bashrc` or `.zshrc` file), for example:
    ```bash
    alias pico-8="~/pico-8-utils/pico-8-dev.sh"
    alias pico-8-log="~/pico-8-utils/pico-8-log.sh"
    ```
## pico-8-dev.sh

A script to start PICO-8 while showing the logs in your console and automatically commit and push changes to your repository.

### Usage

1. Run `./pico-8-dev.sh`
2. The script will automatically pull the latest changes from your repository. And start PICO-8.
3. In your PICO-8 cart create a new function something like this:
    ```lua
    function log(m,o)
        printh(m,"debug/log.txt",o)
    end
   ```
   where `m` is the message you want to log, `o` is the optional flag to override the file. I only call it with `o=true` on `init()` to clear the file.
4. In your console you should now see the log messages. Alternatively you can run `pico-8-log.sh` to view the log file in a separate terminal (via ssh for example)
5. When you exit PICO-8, the script will automatically commit and push the changes to your repository, if there are any changes. You will be prompted to enter a commit message, or press Enter for a default message. Press r to reset the changes or press q to quit without committing.

## pico-8-play.sh

A script to pull the latest changes from your repository and start PICO-8. Without committing or pushing changes when you are done. Useful for devices that you want to use for testing.

### Usage

1. Run `./pico-8-play.sh`
2. The script will automatically pull the latest changes from your repository. And start PICO-8. **THIS WILL OVERWRITE YOUR CURRENT CHANGES**
3. When you exit PICO-8, the script will automatically stop.

## pico-8-log.sh

A script to view the log file in a separate terminal (via ssh for example).

### Usage

1. Run `./pico-8-log.sh`
2. The script will automatically start tailing the log file.