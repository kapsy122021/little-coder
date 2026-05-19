#!/bin/bash
# Start the Little-Coder project (little-coder agent + open-terminal services)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

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

echo "🚀 Starting Little-Coder project..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "✅ Services started successfully!"
echo ""
echo "📋 Running services:"
echo "  • little-coder    (agent runtime, talks to host llama-ingress-proxy via host.docker.internal:8000)"
echo "  • open-terminal   (workspace + shell API at http://127.0.0.1:8001)"
echo ""
echo "🔌 Launch the agent:"
echo "  docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b"
echo "  docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b-nothink"
echo ""
echo "📝 Logs:"
echo "  docker logs -f little-coder"
echo "  docker logs -f open-terminal"
echo ""


