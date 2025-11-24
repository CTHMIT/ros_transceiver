#!/bin/bash
set -e

CONFIG_TEMPLATE="/etc/zenoh/zenoh_config.json5.template"
CONFIG_FILE="/etc/zenoh/zenoh_config.json5"

if [ -f "$CONFIG_TEMPLATE" ]; then
    echo "Generating Zenoh configuration from template..."
    envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
else
    echo "Warning: No configuration template found at $CONFIG_TEMPLATE"
fi

exec "$@"
