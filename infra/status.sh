#!/bin/bash
# Show status of the isolated stack

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/open-terminal-isolated.compose.yml"

echo "📊 Stack Status"
echo "==============="
echo ""

docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "📋 Networks"
echo "==========="
docker network ls | grep -E "ot-net|lc-net" || echo "Networks not created yet"

echo ""
echo "📦 Volumes"
echo "=========="
docker volume ls | grep open-terminal || echo "No volumes yet"
