#!/bin/bash
# Unified run-or-raise script for niri
# Usage: ./ror.sh --app-id <id> --command <cmd> [options]

rorhome=/home/nik/dev/ror
app_id=""
title=""
command=""
app_name=""
cwd=""
operation=""
exclude_focused="false"
printdebug="false"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-id) app_id="$2"; shift ;;
        --title) title="$2"; shift ;;
        --command) command="$2"; shift ;;
        --app-name) app_name="$2"; shift ;;
        --cwd) cwd="$2"; shift ;;
        --operation) operation="$2"; shift ;;
        --exclude-focused) exclude_focused="true" ;;
        --printdebug) printdebug="true" ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$app_name" ]]; then
    # Fallback app_name if not provided, try to use app_id or title
    if [[ -n "$app_id" ]]; then
        app_name="$app_id"
    elif [[ -n "$title" ]]; then
        app_name="$title"
    else
        app_name="Application"
    fi
fi

if [[ -z "$command" ]]; then
    echo "Error: --command is required"
    exit 1
fi

launch() {
    dunstify -a "ror" -t 500 "Starting $app_name"
    if [[ -n "$cwd" ]]; then
        cd "$cwd" || exit
    fi
    $command &
}

search() {
    cd "$rorhome" || exit
    
    # Construct jq arguments dynamically
    jq_args=(--arg app_id "$app_id" --arg title "$title" --arg exclude_focused "$exclude_focused" --arg operation "$operation" --arg printdebug "$printdebug")
    
    winid=$(jq -f "$rorhome/ws.jq" "${jq_args[@]}" < <(niri msg -j windows))

    echo "Found winid: $winid" >> /tmp/ror.log

    if [[ "$winid" == "null" || -z "$winid" ]]; then
        launch
    else
        dunstify -a "ror" -t 500 "Found $app_name" "Raising window..."
        niri msg action focus-window --id "$winid"
    fi
}

search
