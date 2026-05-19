#!/bin/bash
# Show status of the Little-Coder project services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

echo "📊 Little-Coder Status"
echo "======================="
echo ""

docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "📡 External Access:"
echo "  • Terminal API: http://127.0.0.1:8001"
echo ""
echo "📝 Logs:"
echo "  docker logs -f little-coder"
echo "  docker logs -f open-terminal"
echo ""


