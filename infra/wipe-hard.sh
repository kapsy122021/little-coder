#!/bin/bash
# Hard wipe: destroy container and rebuild for full reset

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.unified.yml"

echo "⚠️  WARNING: This will destroy the Little-Coder container and remove all data."
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

echo ""
echo "💥 Performing hard wipe..."
docker compose -f "$COMPOSE_FILE" down

# Remove built images to force rebuild
docker image rm little-coder:latest 2>/dev/null || true

echo "🔄 Rebuilding container from scratch..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "✅ Hard wipe complete. Container rebuilt from clean state."
echo "   All project data, shell history, and caches removed."


