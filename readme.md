# PICO-8 Utilities

Couple of scripts to make development on PICO-8 easier.

## Common Setup

1. Clone this repository
2. Create this machine's config from the template (`pico-8-config.sh` is gitignored, so every device keeps its own paths and a `git pull` never overrides them):
   ```bash
   cp pico-8-config.sh.example pico-8-config.sh
   ```
   Then adjust the paths in `pico-8-config.sh`. `CARTS_DIR` must match `root_path` in PICO-8's own `config.txt`, otherwise the git sync silently does nothing.
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
    chmod +x pico-8-dev.sh pico-8-play.sh pico-8-log.sh
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

## KNULLI handhelds (Anbernic RG35xx etc.)

On KNULLI, PICO-8 is launched through EmulationStation, so instead of `pico-8-play.sh` the device gets a small wrapper around the native PICO-8 binary (`knulli/pico8`) that pulls the latest carts from GitHub before every launch. KNULLI ships no git, so the wrapper downloads a snapshot tarball over HTTPS instead of doing a `git pull`. Offline it times out after a few seconds and launches with the carts already on the device — same offline-friendly behaviour as the other scripts.

The sync is one-way (GitHub → device) and additive: carts deleted from the repo are not deleted from the device.

### Setup

1. Install native PICO-8 on the device as described in the [KNULLI wiki](https://knulli.org/systems/pico-8/) (binaries in `/userdata/bios/pico-8/`).
2. Check `REPO` and `BRANCH` at the top of `knulli/pico8`.
3. If the carts repo is private, create a fine-grained GitHub personal access token with read-only **Contents** access to just that repo.
4. With the device on wifi, run:
    ```bash
    ./knulli/install-to-knulli.sh
    ```
    Default target is `root@knulli.local` (pass `user@host` as argument to override), default SSH password is `linux`. Paste the token when prompted — it is stored on the device at `/userdata/system/pico8-github-token`.
5. Launch Splore or any cart on the device — it syncs first, then starts.

Notes:
- The installer is safe to re-run; it renames the real binary to `pico8.real` once and just refreshes the wrapper afterwards.
- A KNULLI update or reinstalling the PICO-8 binaries may overwrite the wrapper — just run the installer again.
- Sync output lands in the emulator launch log (`/userdata/system/logs/`), useful if carts don't show up.