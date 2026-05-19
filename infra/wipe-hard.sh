#!/bin/bash
# Hard wipe: destroy container and remove all volumes for full reset

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/open-terminal-isolated.compose.yml"

echo "⚠️  WARNING: This will destroy the open-terminal container and remove all persistent data."
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

echo ""
echo "💥 Performing hard wipe..."
docker compose -f "$COMPOSE_FILE" down
docker volume rm open-terminal-home 2>/dev/null || true

echo "🔄 Recreating container from clean state..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "✅ Hard wipe complete. Container reset to clean state."
echo "   All project data and shell history removed."
