# High-Performance ROS 2 Zenoh Bridge

This repository contains a complete setup for a high-performance, low-latency ROS 2 bridge between a Jetson AGX Orin (Client) and a Server PC (x86) using [Eclipse Zenoh](https://zenoh.io/).

## Architecture

-   **Client (Jetson AGX Orin)**: Runs ROS 2 Humble and Zenoh Bridge in Client mode. Connects to the Server.
-   **Server (PC x86)**: Runs ROS 2 Humble and Zenoh Bridge in Router mode. Listens for connections.
-   **Transport**: TCP (configured for reliability). Can be switched to QUIC for lossy networks.
-   **ROS Domain ID**: 161

## Prerequisites

-   **Jetson AGX Orin**: JetPack 5.x or 6.x (Ubuntu 20.04/22.04), Docker, Docker Compose.
-   **Server PC**: Ubuntu 22.04, Docker, Docker Compose.
-   **Network**: Both devices must be on the same network (or reachable via IP).
    -   Server IP: Configured in `config/.env`
    -   Jetson IP: Configured in `config/.env`
    -   Port `7447` must be open on the Server.

## Installation & Usage

### 0. Configuration (Both Devices)

1.  Copy the example configuration file:
    ```bash
    cp config/.env.example config/.env
    ```
2.  Edit `config/.env` and set the `ZENOH_CONNECT_ENDPOINT` (Server IP) and other variables.

### 1. Server PC Setup (Receiver)

1.  Navigate to the server directory:
    ```bash
    cd ros2_zenoh_bridge/server_pc
    ```
2.  Start the bridge:
    ```bash
    ./run_server.sh
    ```
    This will build the Docker image and start the container in host networking mode.

### 2. Client Setup (Jetson AGX Orin)

1.  **Navigate to the client directory:**
    ```bash
    cd ros2_zenoh_bridge/client_orin
    ```

2.  **Start System (Tmux):**
    We provide a systematic launch script using `tmux` to run the Zenoh bridge and the nvblox application in parallel panes.
    ```bash
    ./start_orin_tmux.sh
    ```
    *   **Prerequisite**: Ensure `tmux` is installed (`sudo apt install tmux`) and `ISAAC_ROS_WS` is set.
    *   **Dashboard**:
        *   **Top Pane**: Zenoh Bridge logs.
        *   **Bottom Pane**: Isaac ROS container and nvblox launch.
    *   **Controls**:
        *   Detach: `Ctrl+b` then `d`.
        *   Kill: `Ctrl+c` in each pane or `tmux kill-session -t ros2_bridge`.

### 3. Server Setup (PC)

1.  **On Jetson (Client)**:
    Publish a test topic:
    ```bash
    docker exec -it ros2-zenoh-bridge-client bash
    source /opt/ros/humble/setup.bash
    ros2 topic pub /test_topic std_msgs/msg/String "data: 'Hello from Orin'"
    ```

2.  **On Server (PC)**:
    Listen for the topic:
    ```bash
    docker exec -it ros2-zenoh-bridge-server bash
    source /opt/ros/humble/setup.bash
    ros2 topic echo /test_topic
    ```

## Performance Tuning

-   **Network Mode**: We use `network_mode: "host"` in `docker-compose.yml` to minimize container network overhead.
-   **Transport**: If you experience packet loss on Wi-Fi, switch to QUIC.
    -   Edit `zenoh_client.json5` and `zenoh_server.json5`.
    -   Change `tcp/...` to `quic/...`.
-   **QoS**: Ensure your ROS 2 publishers/subscribers use compatible QoS settings (Reliability: Best Effort is often better for high-frequency sensor data over Wi-Fi).

## Troubleshooting

-   **No Connection**: Check if the Server IP is reachable from the Jetson (`ping 10.28.134.82`). Check firewall settings (`ufw status`).
-   **Discovery Issues**: Ensure `ROS_DOMAIN_ID=161` is set correctly in your ROS 2 nodes (the bridge handles this for its internal ROS node).
