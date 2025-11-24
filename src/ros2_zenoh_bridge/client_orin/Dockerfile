FROM ros:humble-ros-base

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

ENV ZENOH_BRIDGE_VERSION=1.0.0
RUN curl -L -o /tmp/zenoh-bridge-ros2dds.zip https://github.com/eclipse-zenoh/zenoh-plugin-ros2dds/releases/download/${ZENOH_BRIDGE_VERSION}/zenoh-bridge-ros2dds-${ZENOH_BRIDGE_VERSION}-aarch64-unknown-linux-gnu.zip \
    && unzip /tmp/zenoh-bridge-ros2dds.zip -d /usr/local/bin \
    && rm /tmp/zenoh-bridge-ros2dds.zip \
    && chmod +x /usr/local/bin/zenoh-bridge-ros2dds

WORKDIR /workspace

COPY ros_transceiver/src/ros2_zenoh_bridge/client_orin/zenoh_client.json5 /etc/zenoh/zenoh_config.json5.template
COPY ros_transceiver/src/ros2_zenoh_bridge/common/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh", "zenoh-bridge-ros2dds", "-c", "/etc/zenoh/zenoh_config.json5"]
