#!/bin/bash
# Stop the Little-Coder project (little-coder agent + open-terminal)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

echo "🛑 Stopping Little-Coder project..."
docker compose -f "$COMPOSE_FILE" down

echo "✅ Container stopped."


