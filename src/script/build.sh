#!/bin/bash

set -e

echo "----------------------------------------------------------------"
echo "Installing System Dependencies..."
echo "----------------------------------------------------------------"

sudo apt-get update

sudo apt-get install -y \
    tmux \
    curl \
    wget \
    git \
    net-tools

echo "----------------------------------------------------------------"
echo "Checking Docker Environment..."
echo "----------------------------------------------------------------"

if command -v docker &> /dev/null; then
    echo "Docker is installed: $(docker --version)"
else
    echo "WARNING: Docker is NOT installed."
    echo "Please install Docker manually for your platform (Jetson/PC)."
fi

if docker compose version &> /dev/null; then
    echo "Docker Compose is installed: $(docker compose version)"
else
    echo "WARNING: Docker Compose is NOT installed."
    echo "Please install Docker Compose plugin."
fi

echo "----------------------------------------------------------------"
echo "Build Setup Complete."
echo "----------------------------------------------------------------"
