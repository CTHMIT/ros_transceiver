#!/bin/bash
echo "Starting ROS 2 Zenoh Bridge Server on PC..."

# Check for .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Configuration file not found at $ENV_FILE"
    echo "Please copy config/.env.example to config/.env and configure it."
    exit 1
fi

cd "$SCRIPT_DIR"
docker compose up -d --build
echo "Bridge started. Logs:"
docker compose logs -f
