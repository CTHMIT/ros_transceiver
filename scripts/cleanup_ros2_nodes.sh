#!/bin/bash
# Comprehensive ROS2 Node Cleanup Script
# This script kills all ROS2 nodes and processes

set -e

echo "==========================================="
echo "ROS2 Node Cleanup Utility"
echo "==========================================="

# Check if ROS2 is available
if ! command -v ros2 &> /dev/null; then
    echo "ERROR: ros2 command not found. Is ROS2 installed?"
    exit 1
fi

# Show current nodes before cleanup
echo ""
echo "Current ROS2 nodes (before cleanup):"
echo "-------------------------------------------"
ros2 node list 2>/dev/null || echo "No nodes found or daemon not running"
echo "-------------------------------------------"
echo ""

read -p "Do you want to kill all these nodes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup process..."
echo "==========================================="

# Stop the ROS2 daemon first
echo "[1/5] Stopping ROS2 daemon..."
ros2 daemon stop 2>/dev/null || true
sleep 1

# Kill specific node processes by name (gracefully first)
echo "[2/5] Sending SIGTERM to ROS2 processes..."

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

# Kill component containers
pkill -SIGTERM -f "component_container" 2>/dev/null || true

# Wait for graceful shutdown
echo "[3/5] Waiting 3 seconds for graceful shutdown..."
sleep 3

# Force kill any remaining processes
echo "[4/5] Force killing remaining processes (SIGKILL)..."
pkill -SIGKILL -f "realsense2_camera_node" 2>/dev/null || true
pkill -SIGKILL -f "realsense_splitter_node" 2>/dev/null || true
pkill -SIGKILL -f "nvblox_node" 2>/dev/null || true
pkill -SIGKILL -f "nvblox_container" 2>/dev/null || true
pkill -SIGKILL -f "visual_slam_node" 2>/dev/null || true
pkill -SIGKILL -f "ros2 launch" 2>/dev/null || true
pkill -SIGKILL -f "ros2 run" 2>/dev/null || true
pkill -SIGKILL -f "launch_ros" 2>/dev/null || true
pkill -SIGKILL -f "component_container" 2>/dev/null || true

# Kill any Python ROS2 nodes
pkill -SIGKILL -f "python.*ros" 2>/dev/null || true

# Kill zenoh bridge
pkill -SIGKILL -f "zenoh-bridge-ros2dds" 2>/dev/null || true

echo "[5/5] Restarting ROS2 daemon..."
sleep 2
ros2 daemon start 2>/dev/null || true
sleep 1

echo ""
echo "==========================================="
echo "Cleanup completed!"
echo "==========================================="
echo ""

# Show remaining nodes after cleanup
echo "Remaining ROS2 nodes (after cleanup):"
echo "-------------------------------------------"
ros2 node list 2>/dev/null || echo "No nodes found (clean!)"
echo "-------------------------------------------"
echo ""

echo "✅ Done! All ROS2 nodes have been cleaned up."
