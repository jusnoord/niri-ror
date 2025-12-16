# ROR

A script that provides run-or-raise (ROR) functionality for [niri](https://github.com/yalter/niri) on wayland, specifically niri now that it supports window focus commands in 0.1.9.

## Usage

```
./ror.sh [options] -- command...
./ror.sh [options] --command "<command string>"
```

Options:
- `--app-id <id>`: match windows whose `app_id` ends with the given value.
- `--title <title>`: match windows whose title contains the given substring.
- `--operation <op>`: `union | intersection | difference | or`. Default: `intersection` when both `--app-id` and `--title` are provided, otherwise falls back to whichever filter is present.
- `--exclude-focused`: drop the currently focused window from the filtered list (useful for cycling).
- `--list`: print the filtered window list and exit (no raise/launch).
- `--printdebug`: print filtered results via jq `debug`.
- `--app-name <name>`: friendly name for notifications.
- `--cwd <path>`: working directory for the launch command.
- `--command "<string>"`: command as a single string; you can also pass the command after `--` to preserve arguments exactly.

If no matching window is found, the provided command is launched; otherwise the first (or next) matching window is focused.

### Examples

- Typical “match profile + title” binding (cycles through matches, launches if none):
  ```
  ror.sh --app-id "msedge-_faolnafnngnfdaknnbpnkhgohbobgegn-Default" \
         --title "Calendar" \
         --operation intersection \
         --app-name "Outlook Calendar" \
         --command "gio launch /home/nik/.local/share/applications/msedge-calendar.desktop"
  ```

- Same, but with an explicit command array:
  ```
  ror.sh --app-id "kitty" -- kitty -1
  ```

- Inspect what would be matched without focusing/launching:
  ```
  ror.sh --app-id "kitty" --list
  ```

## Notes

- `app_id` matching is suffix-based (`endswith`), so you can target app bundles or profile IDs without typing the whole string.
- `jq` modules are loaded from the script directory, so the script can be moved or symlinked anywhere.
- Requires `niri >= 0.1.9`, `jq`, and `dunstify` for notifications.
