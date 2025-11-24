#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
CONFIG_TEMPLATE="${SCRIPT_DIR}/zenoh_server.json5"
CONFIG_FILE="/tmp/zenoh_server.json5"
ROS_DISTRO=${ROS_DISTRO:-humble}  

echo "----------------------------------------------------------------"
echo "Starting ROS 2 Zenoh Bridge Server (PC)..."
echo "----------------------------------------------------------------"

cleanup() {
    echo ""
    echo ">>> Performing safe shutdown..."
    
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        echo " [OK] Removed temporary config file: $CONFIG_FILE"
    fi
    
    echo ">>> Server stopped safely."
}
trap cleanup EXIT INT TERM

if [ ! -f "$ENV_FILE" ]; then
    echo " [Error] Configuration file not found: $ENV_FILE"
    echo " Please verify the path or copy config/.env.example to config/.env."
    exit 1
fi

if [ ! -f "$CONFIG_TEMPLATE" ]; then
    echo " [Error] Zenoh config template not found: $CONFIG_TEMPLATE"
    exit 1
fi

if ! command -v zenoh-bridge-ros2dds &> /dev/null; then
    echo " [Error] zenoh-bridge-ros2dds command not found."
    echo " Please install it using the following commands:"
    echo " echo 'deb [trusted=yes] https://download.eclipse.org/zenoh/debian-repo/ /' | sudo tee -a /etc/apt/sources.list > /dev/null"
    echo " sudo apt-get update && sudo apt-get install -y zenoh-bridge-ros2dds"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

echo " [Info] ROS Distro: $ROS_DISTRO"
echo " [Info] ROS Domain ID: ${ROS_DOMAIN_ID}"
echo " [Info] Listen Endpoint: ${ZENOH_LISTEN_ENDPOINT}"

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
else
    echo " [Warning] Could not find /opt/ros/${ROS_DISTRO}/setup.bash. Assuming you sourced it manually."
fi

export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"

if [ ! -s "$CONFIG_FILE" ]; then
    echo " [Error] Failed to generate config file (file is empty). Please check if 'envsubst' is installed (sudo apt install gettext-base)."
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Startup successful! Press Ctrl+C to exit safely."
echo "----------------------------------------------------------------"

zenoh-bridge-ros2dds -c "$CONFIG_FILE"