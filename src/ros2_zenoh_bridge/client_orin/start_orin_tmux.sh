#!/bin/bash

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install it:"
    echo "sudo apt-get update && sudo apt-get install -y tmux"
    exit 1
fi

# Check for ISAAC_ROS_WS
if [ -z "$ISAAC_ROS_WS" ]; then
    echo "Error: ISAAC_ROS_WS environment variable is not defined."
    echo "Please source your Isaac ROS workspace setup script."
    exit 1
fi

# Check for .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Configuration file not found at $ENV_FILE"
    echo "Please copy config/.env.example to config/.env and configure it."
    exit 1
fi

SESSION_NAME="ros2_bridge"

# Check if session already exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Session $SESSION_NAME already exists. Attaching..."
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

# Create new session
# Pane 0 (Top): Zenoh Bridge
tmux new-session -d -s $SESSION_NAME -n "Bridge"
tmux send-keys -t $SESSION_NAME:0 "cd ${SCRIPT_DIR}" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Starting Zenoh Bridge...'" C-m
tmux send-keys -t $SESSION_NAME:0 "docker compose -f docker-compose.yml up --build" C-m

# Split window vertically
tmux split-window -v -t $SESSION_NAME:0

# Pane 1 (Bottom): Isaac ROS nvblox
tmux send-keys -t $SESSION_NAME:0.1 "echo 'Waiting for bridge to initialize...'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "sleep 5" C-m
tmux send-keys -t $SESSION_NAME:0.1 "cd ${ISAAC_ROS_WS}/src/isaac_ros_common" C-m
tmux send-keys -t $SESSION_NAME:0.1 "./scripts/run_dev.sh ros2 launch nvblox_examples_bringup realsense_example.launch.py run_rviz:=false" C-m

# Select top pane
tmux select-pane -t $SESSION_NAME:0.0

# Attach to session
tmux attach-session -t $SESSION_NAME
