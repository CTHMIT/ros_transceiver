#!/bin/bash
set -e

# Configuration file paths
CONFIG_TEMPLATE="/etc/zenoh/zenoh_config.json5.template"
CONFIG_FILE="/etc/zenoh/zenoh_config.json5"

if [ -f "$CONFIG_TEMPLATE" ]; then
    echo "Generating Zenoh configuration from template..."
    # Use envsubst to replace variables in the template
    # We explicitly list variables to avoid replacing system variables if not intended,
    # but for simplicity here we'll replace all exported variables.
    envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
else
    echo "Warning: No configuration template found at $CONFIG_TEMPLATE"
fi

# Execute the command passed to the docker container
exec "$@"
