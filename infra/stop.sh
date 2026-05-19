#!/bin/bash
# Stop the unified Little-Coder container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.unified.yml"

echo "🛑 Stopping Little-Coder container..."
docker compose -f "$COMPOSE_FILE" down

echo "✅ Container stopped."


