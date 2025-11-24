#!/bin/bash

if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install it:"
    echo "sudo apt-get update && sudo apt-get install -y tmux"
    exit 1
fi

if [ -z "$ISAAC_ROS_WS" ]; then
    echo "Error: ISAAC_ROS_WS environment variable is not defined."
    echo "Please source your Isaac ROS workspace setup script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Configuration file not found at $ENV_FILE"
    echo "Please copy config/.env.example to config/.env and configure it."
    exit 1
fi


check_and_install_zenoh() {
    if ! command -v zenoh-bridge-ros2dds &> /dev/null; then
        echo "zenoh-bridge-ros2dds not found. Installing..."
        
        echo "deb [trusted=yes] https://download.eclipse.org/zenoh/debian-repo/ /" | sudo tee -a /etc/apt/sources.list > /dev/null
        sudo apt-get update
        
        sudo apt-get install -y zenoh-bridge-ros2dds gettext-base
        
        if ! command -v zenoh-bridge-ros2dds &> /dev/null; then
            echo "Error: Failed to install zenoh-bridge-ros2dds."
            exit 1
        fi
        echo "zenoh-bridge-ros2dds installed successfully."
    else
        echo "zenoh-bridge-ros2dds is already installed."
    fi
}

check_and_install_zenoh

CONFIG_TEMPLATE="${SCRIPT_DIR}/zenoh_client.json5"
CONFIG_FILE="/tmp/zenoh_client.json5"

if [ -f "$CONFIG_TEMPLATE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
else
    echo "Error: Config template not found at $CONFIG_TEMPLATE"
    exit 1
fi

SESSION_NAME="ros2_bridge"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session $SESSION_NAME already exists. Killing it..."
    tmux kill-session -t $SESSION_NAME
fi

tmux new-session -d -s $SESSION_NAME -n "Bridge"
tmux send-keys -t $SESSION_NAME:0 "cd ${SCRIPT_DIR}" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Starting Zenoh Bridge...'" C-m
tmux send-keys -t $SESSION_NAME:0 "zenoh-bridge-ros2dds -c ${CONFIG_FILE}" C-m

tmux split-window -v -t $SESSION_NAME:0

tmux send-keys -t $SESSION_NAME:0.1 "echo 'Waiting for bridge to initialize...'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "sleep 5" C-m
tmux send-keys -t $SESSION_NAME:0.1 "IsaacRos" C-m
tmux send-keys -t $SESSION_NAME:0.1 "source install/setup.bash" C-m
tmux send-keys -t $SESSION_NAME:0.1 "ros2 launch nvblox_examples_bringup realsense_example.launch.py run_rviz:=false" C-m

tmux select-pane -t $SESSION_NAME:0.0

tmux attach-session -t $SESSION_NAME
