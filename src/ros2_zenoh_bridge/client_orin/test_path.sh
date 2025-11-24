#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../config/.env"
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "ENV_FILE: $ENV_FILE"
if [ -f "$ENV_FILE" ]; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi
