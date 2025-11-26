#!/bin/bash
set -e  # Exit on error (but allow cleanup)

SESSION_NAME="ros2_transceiver"
CONFIG_FILE="/tmp/zenoh_server.json5"
CLEANUP_IN_PROGRESS=false

# Detect if running in Docker
is_docker() {
    [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null
}

# Cleanup function with improved robustness
cleanup() {
    # Prevent multiple cleanup calls
    if [ "$CLEANUP_IN_PROGRESS" = true ]; then
        return
    fi
    CLEANUP_IN_PROGRESS=true
    
    echo ""
    echo "==========================================="
    echo "Initiating cleanup process..."
    echo "==========================================="
    
    # Kill all ROS2 nodes in the current ROS_DOMAIN_ID
    if [ -n "$ROS_DOMAIN_ID" ]; then
        echo "Cleaning up ROS2 nodes in domain $ROS_DOMAIN_ID..."
        
        if command -v ros2 &> /dev/null; then
            # Stop the ROS2 daemon first
            echo "Stopping ROS2 daemon..."
            ros2 daemon stop 2>/dev/null || true
            sleep 1
            
            # Kill specific node processes by name (gracefully first)
            echo "Terminating ROS2 node processes..."
            
            # Kill camera nodes
            pkill -SIGTERM -f "realsense2_camera_node" 2>/dev/null || true
            pkill -SIGTERM -f "realsense_splitter_node" 2>/dev/null || true
            
            # Kill nvblox nodes
            pkill -SIGTERM -f "nvblox_node" 2>/dev/null || true
            pkill -SIGTERM -f "nvblox_container" 2>/dev/null || true
            
            # Kill visual slam nodes
            pkill -SIGTERM -f "visual_slam_node" 2>/dev/null || true
            
            # Kill generic ros2 launch/run processes
            pkill -SIGTERM -f "ros2 launch" 2>/dev/null || true
            pkill -SIGTERM -f "ros2 run" 2>/dev/null || true
            
            # Kill any launch_ros processes
            pkill -SIGTERM -f "launch_ros" 2>/dev/null || true
            
            # Wait for graceful shutdown
            echo "Waiting for graceful shutdown..."
            sleep 3
            
            # Force kill any remaining processes
            echo "Force killing remaining processes..."
            pkill -SIGKILL -f "realsense2_camera_node" 2>/dev/null || true
            pkill -SIGKILL -f "realsense_splitter_node" 2>/dev/null || true
            pkill -SIGKILL -f "nvblox_node" 2>/dev/null || true
            pkill -SIGKILL -f "nvblox_container" 2>/dev/null || true
            pkill -SIGKILL -f "visual_slam_node" 2>/dev/null || true
            pkill -SIGKILL -f "ros2 launch" 2>/dev/null || true
            pkill -SIGKILL -f "ros2 run" 2>/dev/null || true
            pkill -SIGKILL -f "launch_ros" 2>/dev/null || true
            
            # Kill any Python ROS2 nodes
            pkill -SIGKILL -f "python.*ros" 2>/dev/null || true
            
            echo "ROS2 nodes terminated."
        fi
    fi
    
    # Kill zenoh bridge processes
    echo "Stopping Zenoh bridge..."
    pkill -SIGTERM -f "zenoh-bridge-ros2dds" 2>/dev/null || true
    sleep 1
    pkill -SIGKILL -f "zenoh-bridge-ros2dds" 2>/dev/null || true
    
    # Clean up tmux session
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "Terminating tmux session: $SESSION_NAME"
        
        # Send SIGTERM to all processes in tmux session
        tmux list-panes -s -t "$SESSION_NAME" -F "#{pane_pid}" 2>/dev/null | while read pid; do
            if [ -n "$pid" ]; then
                kill -TERM "$pid" 2>/dev/null || true
            fi
        done
        
        # Wait for graceful shutdown
        sleep 2
        
        # Force kill tmux session
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
        echo "Tmux session terminated: $SESSION_NAME"
    fi
    
    # Remove temporary config file
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        echo "Removed temporary config file: $CONFIG_FILE"
    fi
    
    echo "==========================================="
    echo "Cleanup completed successfully."
    echo "==========================================="
    
    exit 0
}

# Setup signal handlers
trap cleanup EXIT
trap cleanup INT
trap cleanup TERM
trap cleanup SIGINT
trap cleanup SIGTERM

if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install it:"
    echo "sudo apt-get update && sudo apt-get install -y tmux"
    exit 1
fi

# Check ISAAC_ROS_WS (skip in Docker as it might be mounted differently)
if [ -z "$ISAAC_ROS_WS" ] && ! is_docker; then
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

CONFIG_TEMPLATE="${SCRIPT_DIR}/zenoh_server.json5"

if [ -f "$CONFIG_TEMPLATE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"
else
    echo "Error: Config template not found at $CONFIG_TEMPLATE"
    exit 1
fi

ROS_DISTRO=${ROS_DISTRO:-humble}

# Clean up any existing session
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "WARNING: Session $SESSION_NAME already exists. Cleaning up..."
    tmux kill-session -t $SESSION_NAME
    sleep 1
fi

echo "==========================================="
echo "Starting ROS2 Transceiver System"
echo "Session: $SESSION_NAME"
echo "ROS Distribution: $ROS_DISTRO"
echo "ROS Domain ID: ${ROS_DOMAIN_ID:-0}"
echo "Docker Mode: $(is_docker && echo 'Yes' || echo 'No')"
echo "==========================================="

# Create new tmux session
tmux new-session -d -s $SESSION_NAME -n "Receiver"

# ====== Pane 0: Zenoh Bridge ======
echo "Setting up Zenoh Bridge (Pane 0)..."
tmux send-keys -t $SESSION_NAME:0 "cd ${SCRIPT_DIR}" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '========================================='" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'Starting Zenoh Bridge...'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '========================================='" C-m

# Source environment (fixed the set -a command)
tmux send-keys -t $SESSION_NAME:0 "set -a" C-m
tmux send-keys -t $SESSION_NAME:0 "source \"$ENV_FILE\"" C-m
tmux send-keys -t $SESSION_NAME:0 "set +a" C-m

tmux send-keys -t $SESSION_NAME:0 "source /opt/ros/${ROS_DISTRO}/setup.bash" C-m
tmux send-keys -t $SESSION_NAME:0 "export ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-${ROS_DOMAIN_ID}}" C-m

# Add trap in tmux pane to handle SIGINT
tmux send-keys -t $SESSION_NAME:0 "trap 'echo \"Zenoh Bridge stopped.\"; exit 0' SIGINT SIGTERM" C-m
tmux send-keys -t $SESSION_NAME:0 "zenoh-bridge-ros2dds -c ${CONFIG_FILE}" C-m

# ====== Pane 1: Isaac ROS Nvblox ======
echo "Setting up Isaac ROS Nvblox (Pane 1)..."
tmux split-window -v -t $SESSION_NAME:0

tmux send-keys -t $SESSION_NAME:0.1 "echo 'Waiting for Zenoh bridge to initialize...'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "sleep 3" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '========================================='" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo 'Starting Isaac ROS Nvblox...'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '========================================='" C-m

# Only run IsaacRos if not in Docker (it's likely a custom command)
if ! is_docker; then
    tmux send-keys -t $SESSION_NAME:0.1 "IsaacRos 2>/dev/null || echo 'IsaacRos command not found, continuing...'" C-m
fi

tmux send-keys -t $SESSION_NAME:0.1 "source /opt/ros/${ROS_DISTRO}/setup.bash" C-m
tmux send-keys -t $SESSION_NAME:0.1 "export ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-${ROS_DOMAIN_ID}}" C-m
tmux send-keys -t $SESSION_NAME:0.1 "source install/setup.bash 2>/dev/null || echo 'Warning: install/setup.bash not found'" C-m

# Add trap in tmux pane to handle SIGINT
tmux send-keys -t $SESSION_NAME:0.1 "trap 'echo \"ROS2 nodes stopped.\"; exit 0' SIGINT SIGTERM" C-m
tmux send-keys -t $SESSION_NAME:0.1 "ros2 launch nvblox_examples_bringup visualization.launch.py" C-m

# Select the first pane
tmux select-pane -t $SESSION_NAME:0.0

echo ""
echo "==========================================="
echo "System started successfully!"
echo "Press Ctrl+C to stop all processes gracefully."
echo "==========================================="
echo ""

# Attach to tmux session (this blocks until user exits)
tmux attach-session -t $SESSION_NAME