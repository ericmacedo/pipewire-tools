#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

show_help() {
    echo "Usage: pipewire-tools cycle [direction]"
    echo ""
    echo "Cycle the active output device forward or backward."
    echo ""
    echo "Arguments:"
    echo "  1    Cycle forward (default)"
    echo " -1    Cycle backward"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

direction=${1:-1}

if [[ "$direction" != "1" && "$direction" != "-1" ]]; then
    echo "Error: Invalid direction parameter."
    echo ""
    show_help
    exit 1
fi

mapfile -t sinks < <(get_sinks)
current=$(wpctl status | awk '/Sinks:/{f=1;next} /├─/{f=0} f && /\*/ {if (match($0, /[0-9]+\./)) print substr($0, RSTART, RLENGTH-1)}')

if [[ -z "$current" ]] || [[ ${#sinks[@]} -eq 0 ]]; then
    echo "Error: Could not detect active sink or found no sinks."
    exit 1
fi

num_sinks=${#sinks[@]}
current_index=-1

for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current" ]]; then
        current_index=$i
        break
    fi
done

if [[ $current_index -eq -1 ]]; then
    echo "Error: Current sink not found in sinks list."
    exit 1
fi

for (( j=1; j<=num_sinks; j++ )); do
    if [[ "$direction" == "1" ]]; then
        next_index=$(( (current_index + j) % num_sinks ))
    else
        next_index=$(( (current_index - j + num_sinks) % num_sinks ))
    fi
    
    next_sink="${sinks[$next_index]}"
    
    if wpctl inspect "$next_sink" | grep -q 'node.cycle.ignore = "true"'; then
        continue
    fi
    
    wpctl set-default "$next_sink"
    
    new_current=$(wpctl status | awk '/Sinks:/{f=1;next} /├─/{f=0} f && /\*/ {if (match($0, /[0-9]+\./)) print substr($0, RSTART, RLENGTH-1)}')
    
    if [[ "$new_current" == "$next_sink" ]]; then
        break
    fi
done