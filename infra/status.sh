#!/bin/bash
# Show status of the unified Little-Coder container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.unified.yml"

echo "📊 Little-Coder Container Status"
echo "=================================="
echo ""

docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "📋 Internal Services (inside container):"
echo "  • little-coder      (Node.js) → localhost:3000"
echo "  • open-terminal     (Uvicorn) → localhost:8000"
echo ""
echo "📡 External Access:"
echo "  • Terminal API: http://127.0.0.1:8001"
echo ""
echo "📝 Logs:"
echo "  docker logs -f little-coder"
echo ""


