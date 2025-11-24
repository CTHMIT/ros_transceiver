#!/bin/bash
echo "Starting ROS 2 Zenoh Bridge Server on PC..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Configuration file not found at $ENV_FILE"
    echo "Please copy config/.env.example to config/.env and configure it."
    exit 1
fi


set -a
source "$ENV_FILE"
set +a

echo 'Starting Zenoh Bridge...'
source /opt/ros/${ROS_DISTRO}/setup.bash
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}
zenoh-bridge-ros2dds -c ${CONFIG_FILE}