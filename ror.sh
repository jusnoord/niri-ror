#!/bin/bash
# Unified run-or-raise script for niri
# Usage:
#   ./ror.sh --app-id <id> --title <title> --operation intersection -- command...
#   ./ror.sh --app-id <id> --command "gio launch /path/to/app.desktop"

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
log_file="${ROR_LOG_FILE:-/tmp/ror.log}"

app_id=""
title=""
command_str=""
declare -a command_args=()
app_name=""
cwd=""
operation=""
exclude_focused="false"
printdebug="false"
list_only="false"

usage() {
  cat <<'EOF'
Usage: ror.sh [options] -- command...
       ror.sh [options] --command "<command string>"

Options:
  --app-id <id>           Window app_id suffix to match (endswith).
  --title <title>         Substring to match in window title.
  --operation <op>        union | intersection | difference | or. Default: intersection when both app-id and title are present, else best effort.
  --app-name <name>       Friendly name for notifications (defaults to app-id/title).
  --cwd <path>            Working directory for the command.
  --exclude-focused       Exclude currently focused window from cycling.
  --printdebug            Print filtered results to stderr via jq debug.
  --list                  Print filtered window list and exit (no focus/launch).
  --command "<string>"    Command string (word-split) to run if no match is found.
  --help                  Show this help.

Command:
  Pass the command either as a string via --command, or after a literal -- so
  it is preserved as-is: ror.sh ... -- gio launch /path/app.desktop
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --app-id)
      [[ $# -lt 2 ]] && { echo "Missing value for --app-id" >&2; exit 1; }
      app_id="$2"; shift 2;;
    --title)
      [[ $# -lt 2 ]] && { echo "Missing value for --title" >&2; exit 1; }
      title="$2"; shift 2;;
    --command)
      [[ $# -lt 2 ]] && { echo "Missing value for --command" >&2; exit 1; }
      command_str="$2"; shift 2;;
    --app-name)
      [[ $# -lt 2 ]] && { echo "Missing value for --app-name" >&2; exit 1; }
      app_name="$2"; shift 2;;
    --cwd)
      [[ $# -lt 2 ]] && { echo "Missing value for --cwd" >&2; exit 1; }
      cwd="$2"; shift 2;;
    --operation)
      [[ $# -lt 2 ]] && { echo "Missing value for --operation" >&2; exit 1; }
      operation="$2"; shift 2;;
    --exclude-focused)
      exclude_focused="true"; shift;;
    --printdebug)
      printdebug="true"; shift;;
    --list)
      list_only="true"; shift;;
    --help)
      usage; exit 0;;
    --)
      shift
      command_args=("$@")
      break;;
    *)
      echo "Unknown parameter: $1" >&2
      usage
      exit 1;;
  esac
done

if [[ ${#command_args[@]} -eq 0 && -n "$command_str" ]]; then
  # shellcheck disable=SC2206
  command_args=($command_str)
fi

if [[ ${#command_args[@]} -eq 0 ]]; then
  echo "Error: command to launch is required (use --command or pass after --)" >&2
  exit 1
fi

if [[ -z "$app_name" ]]; then
  if [[ -n "$app_id" ]]; then
    app_name="$app_id"
  elif [[ -n "$title" ]]; then
    app_name="$title"
  else
    app_name="Application"
  fi
fi

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$log_file"
}

launch() {
  dunstify -a "ror" -t 500 "Starting $app_name"
  if [[ -n "$cwd" ]]; then
    cd "$cwd" || exit
  fi
  "${command_args[@]}" &
}

search() {
  jq_args=(--arg app_id "$app_id" --arg title "$title" --arg exclude_focused "$exclude_focused" --arg operation "$operation" --arg printdebug "$printdebug" --arg list_only "$list_only")

  winid=$(niri msg -j windows | jq -L "$script_dir" -f "$script_dir/ws.jq" "${jq_args[@]}")

  log "Found winid: $winid"

  if [[ "$list_only" == "true" ]]; then
    printf '%s\n' "$winid"
    exit 0
  fi

  if [[ "$winid" == "null" || -z "$winid" ]]; then
    launch
  else
    dunstify -a "ror" -t 500 "Found $app_name" "Raising window..."
    niri msg action focus-window --id "$winid"
  fi
}

search
