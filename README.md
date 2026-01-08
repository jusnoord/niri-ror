# Run-or-Raise for [niri](https://github.com/YaLTeR/niri)

A script that provides run-or-raise (ROR) functionality for [niri](https://github.com/yalter/niri), specifically now that it supports window focus commands in 0.1.9.

To say that this grew legs is an understatement, but it works very nicely. 


## Usage

Basic usage:

```
./ror.sh [options] -- command...
./ror.sh [options] --command "<command string>"
```

If no matching window is found, the provided command is launched; otherwise the first (or next) matching window is focused. Windows are cycled in the order they were launched (using niri's Window ID #).

See [Examples](#examples) and [Example niri bindings](#example-niri-bindings) sections below for more ideas.

Options:
- `--app-id <id>`: match windows whose `app_id` contains the given value.
- `--title <title>`: match windows whose title contains the given substring.
- `--app-id-regex <re>` / `--title-regex <re>`: regex match on `app_id`/title (takes precedence over the non-regex filter).
- `--operation <op>`: `union`/`or` (either), `intersection`/`and` (both), `difference` (`app_id` minus `title`). Default: `intersection` when both `--app-id`/`--title` (or regex) are provided, otherwise falls back to whichever filter is present.
- `--exclude-focused`: drop the currently focused window from the filtered list (starts a second instance).
- `--list`: print the filtered window list and exit (no raise/launch).
- `--time`: log how long the search/raise took (ms); printed when debugging/listing.
- `--printdebug`: print filtered results via jq `debug`.
- `--app-name <name>`: friendly name for notifications.
- `--cwd <path>`: working directory for the launch command.
- `--jq-filter-file <path>`: jq file that pre-processes the window JSON before the built-in filters.
- `--jq-filter '<expr>'`: inline jq filter (written to a temp file) applied before the built-in filters.
- `--log`: enable file logging (default off) to `$ROR_LOG_FILE` or `/tmp/ror.log` (found/focus/launch/elapsed when `--time`).
- `--notify`: enable desktop notifications (default off).
- `--command "<string>"`: command as a single string; you can also pass the command after `--` to preserve arguments exactly.


### Examples

- Typical “match profile + title” binding (cycles through matches, launches if none):
  ```sh
  ror.sh --app-id "msedge-_faolnafnngnfdaknnbpnkhgohbobgegn-Default" \
         --title "Calendar" \
         --operation intersection \
         --app-name "Outlook Calendar" \
         --notify \
         --command "gio launch /home/nik/.local/share/applications/msedge-calendar.desktop"
  ```

- Same, but with an explicit command array:
  ```sh
  ror.sh --app-id "kitty" --notify -- kitty -1
  ```

- Inspect what would be matched without focusing/launching:
  ```sh
  ror.sh --app-id "kitty" --list --command "kitty"
  ```

- Regex example (match app_id suffix “calendar”):
  ```sh
  ror.sh --app-id-regex 'calendar$' --title "Calendar" --operation intersection --list --command "[launch command]"
  ```

- Apply a custom filter (here: only windows on workspace 1):
  ```sh
  ror.sh --app-id "kitty" --jq-filter 'map(select(.workspace_id == 1))' --list --command "kitty"
  ```
  (Custom filters should still emit an array of window objects.)

### Example niri bindings

This is how I use this script. Taken from my niri config:

```js
// Chrome PWAs
"Mod+Shift+1" { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "chrome-knaiokfnmjjldlfhlioejgcompgenfhb-Default" "--command" "gio launch /home/nik/.local/share/applications/chrome-knaiokfnmjjldlfhlioejgcompgenfhb-Default.desktop" "--app-name" "Todoist"; }

// Electron apps
"Mod+Shift+2" { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "obsidian" "--command" "gio launch /home/nik/.local/share/applications/appimagekit_8c8237c3d919fe4f450c2ed4d2fa0fcc-Obsidian.desktop" "--app-name" "Obsidian"; }

// Neovide with custom working dir
"Mod+Shift+8" { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "neovide" "--command" "neovide" "--cwd" "/home/nik/rcdev/observer" "--app-name" "Neovide in rcdev"; }

// Edge, launching the same PWA with different in-app URLs, showing title regex
"Mod+Shift+9" { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "msedge-_faolnafnngnfdaknnbpnkhgohbobgegn-Default" "--title" "Calendar" "--operation" "intersection" "--command" "gio launch /home/nik/.local/share/applications/msedge-calendar.desktop" "--app-name" "Outlook Calendar"; }
"Mod+Shift+0" { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "msedge-_faolnafnngnfdaknnbpnkhgohbobgegn-Default" "--title-regex" "(?<=.)- Mail -(?=.)" "--operation" "intersection" "--command" "gio launch /home/nik/.local/share/applications/msedge-mail.desktop" "--app-name" "Outlook Mail"; }

// Kitty
"Mod+T"       { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "kitty" "--command" "kitty" "--app-name" "terminal"; }
// with custom window title
"Mod+E"       { spawn "/home/nik/dev/ror/ror.sh" "--app-id" "kitty" "--title" "ssh" "--command" "kitty --title \"sshorsomethingiguess\""  "--app-name" "ssh terminal"; }
```

## Notes

- Requires `niri >= 0.1.9` and `jq`.
- `app_id` and `--title` matching defaults to substring (`contains`). Use regex (e.g., `--title-regex '^Mail'`) if you need a strict suffix.
- With your window running: `niri msg -j windows | jq '.[] | {app_id, title, id, workspace_id}'` and look at the `app_id`/title substring you care about. 
- Logging is opt-in (`--log`); timing still prints to stderr when `--time` is set.
- Custom filters run before the built-in filters; if they return an empty array (`[]`), the script will treat it as “no matches” and launch a new instance. 
- Desktop notifications require `notify-send` (or your own `ROR_NOTIFY_CMD`) and are disabled by default; use `--notify` to enable them. The default command is `notify-send -a "ror" -t 300`. Back in the day I had this using dunstify, e.g. `# ROR_NOTIFY_CMD='dunstify -a "ror" -t 500'`, but now that it's super stable I've found I don't need the notifications any more.

## Development

- Lint/check: `make check` (runs `shellcheck` if available and syntax-checks `ror.sh`, and runs `jq` against `ws.jq`).
- Dependency check: `make deps` (verifies `jq` and `niri`)
- jq modules live in `lib/` and are resolved via the script’s `-L` path; custom filters can also import them.

## Why not Rust

Keeping it to bash + jq makes the whole thing easy to read (trust), and tweak without a giant toolchain. Plus it’s already fast enough (a few milliseconds). 
