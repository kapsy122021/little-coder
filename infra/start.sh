#!/bin/bash
# Start the unified Little-Coder container (both little-coder and open-terminal)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.unified.yml"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "❌ Error: .env file not found at $SCRIPT_DIR/.env"
    echo "Please create .env with OPEN_TERMINAL_API_KEY set."
    exit 1
fi

# Check if API key is still the placeholder
if grep -q "replace-with-long-random-secret" "$SCRIPT_DIR/.env"; then
    echo "⚠️  WARNING: OPEN_TERMINAL_API_KEY is still the placeholder value!"
    echo "Generate a new key with: openssl rand -hex 32"
    echo "Update infra/.env with the generated value."
    exit 1
fi

echo "🚀 Starting unified Little-Coder container..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "✅ Container started successfully!"
echo ""
echo "📋 Services running in single container:"
echo "  • little-coder        (Node.js agent) - port 3000 (internal)"
echo "  • open-terminal       (Uvicorn API)   - port 127.0.0.1:8001"
echo ""
echo "🔌 Access:"
echo "  • Terminal API: curl http://127.0.0.1:8001/api/status"
echo "  • Logs: docker logs -f little-coder"
echo "  • Shell: docker exec -it little-coder /bin/bash"
echo ""


