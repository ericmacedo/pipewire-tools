#!/bin/bash

WP_CONF_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
WP_CONF_FILE="$WP_CONF_DIR/99-pipewire-tools-ignore.conf"

mkdir -p "$WP_CONF_DIR"

get_node_name() {
    local id=$1
    wpctl inspect "$id" 2>/dev/null | awk -F'"' '/\*? *node\.name/ {print $2}'
}

get_ignored_names() {
    if [[ -f "$WP_CONF_FILE" ]]; then
        sed -n 's/.*node\.name = "\([^"]*\)".*/\1/p' "$WP_CONF_FILE"
    fi
}

rebuild_wp_config() {
    local names=("$@")
    
    if [[ ${#names[@]} -eq 0 ]]; then
        rm -f "$WP_CONF_FILE"
    else
        echo "monitor.alsa.rules = [" > "$WP_CONF_FILE"
        for name in "${names[@]}"; do
            cat <<EOF >> "$WP_CONF_FILE"
  {
    matches = [ { node.name = "$name" } ]
    actions = { update-props = { node.cycle.ignore = true } }
  }
EOF
        done
        echo "]" >> "$WP_CONF_FILE"
    fi
    
    systemctl --user restart wireplumber
    echo "WirePlumber restarted to apply changes."
}

get_sinks() {
    wpctl status | awk '/Sinks:/{f=1;next} /├─/{f=0} f{if (match($0, / [0-9]+\./)) print substr($0, RSTART+1, RLENGTH-2)}'
}
