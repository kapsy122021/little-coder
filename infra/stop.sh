#!/bin/bash
# Stop the isolated stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/open-terminal-isolated.compose.yml"

echo "🛑 Stopping stack..."
docker compose -f "$COMPOSE_FILE" down

echo "✅ Stack stopped."
