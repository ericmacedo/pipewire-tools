#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

show_help() {
    echo "Usage: pipewire-tools device <subcommand> [args]"
    echo ""
    echo "Manage output devices and their ignore flags."
    echo ""
    echo "Subcommands:"
    echo "  list               List all available devices and their ignore status"
    echo "  ignore <device_id> Flag a specific device ID to be ignored when cycling"
    echo "  enable <device_id> Remove the ignore flag from a specific device ID"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
}

cmd_list() {
    echo -e "ID\tIGNORE\tNAME\t\t\tDESCRIPTION"
    echo "---------------------------------------------------------------------------------"
    mapfile -t sinks < <(get_sinks)
    for id in "${sinks[@]}"; do
        local node_name
        node_name=$(get_node_name "$id")
        local desc
        desc=$(wpctl inspect "$id" | awk -F'"' '/\*? *node\.description/ {print $2}')
        
        local is_ignored="[ ]"
        if wpctl inspect "$id" | grep -q 'node.cycle.ignore = "true"'; then
            is_ignored="[X]"
        fi
        
        local marker="  "
        if wpctl status | awk '/Sinks:/{f=1;next} /├─/{f=0} f && /\*/ {if (match($0, /[0-9]+\./)) print substr($0, RSTART, RLENGTH-1)}' | grep -q "^$id$"; then
            marker="* "
        fi

        local short_name="${node_name}"
        if [ ${#short_name} -gt 20 ]; then
            short_name="${short_name:0:17}..."
        fi

        printf "%s%s\t%s\t%-20s\t%s\n" "$marker" "$id" "$is_ignored" "$short_name" "$desc"
    done
}

cmd_ignore() {
    local id=$1
    if [[ -z "$id" ]]; then
        echo "Error: Device ID required."
        echo "Usage: pipewire-tools device ignore <device_id>"
        exit 1
    fi
    local node_name
    node_name=$(get_node_name "$id")
    if [[ -z "$node_name" ]]; then
        echo "Error: Could not find node.name for device ID $id"
        exit 1
    fi
    
    mapfile -t current_ignored < <(get_ignored_names)
    
    for name in "${current_ignored[@]}"; do
        if [[ "$name" == "$node_name" ]]; then
            echo "Device $id is already ignored."
            return
        fi
    done
    
    current_ignored+=("$node_name")
    echo "Added $id ($node_name) to ignore list."
    rebuild_wp_config "${current_ignored[@]}"
}

cmd_enable() {
    local id=$1
    if [[ -z "$id" ]]; then
        echo "Error: Device ID required."
        echo "Usage: pipewire-tools device enable <device_id>"
        exit 1
    fi
    local node_name
    node_name=$(get_node_name "$id")
    if [[ -z "$node_name" ]]; then
        echo "Error: Could not find node.name for device ID $id"
        exit 1
    fi
    
    mapfile -t current_ignored < <(get_ignored_names)
    local new_ignored=()
    local found=0
    
    for name in "${current_ignored[@]}"; do
        if [[ "$name" == "$node_name" ]]; then
            found=1
        else
            new_ignored+=("$name")
        fi
    done
    
    if [[ $found -eq 1 ]]; then
        echo "Removed $id ($node_name) from ignore list."
        rebuild_wp_config "${new_ignored[@]}"
    else
        echo "Device $id is not in the ignore list."
    fi
}

subcommand=$1

if [[ -z "$subcommand" || "$subcommand" == "-h" || "$subcommand" == "--help" ]]; then
    show_help
    exit 0
fi

shift

case "$subcommand" in
    list)   cmd_list "$@" ;;
    ignore) cmd_ignore "$@" ;;
    enable) cmd_enable "$@" ;;
    *)      
        echo "Error: Unknown device subcommand '$subcommand'"
        echo ""
        show_help
        exit 1 
        ;;
esac