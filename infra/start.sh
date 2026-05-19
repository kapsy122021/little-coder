#!/bin/bash
# Start the isolated open-terminal and little-coder stack with security defaults

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$SCRIPT_DIR/open-terminal-isolated.compose.yml"

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

echo "🚀 Starting isolated open-terminal and little-coder stack..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "✅ Stack started successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Configure Open WebUI integration:"
echo "     - Go to Integrations"
echo "     - Add Open Terminal connection"
echo "     - URL: http://127.0.0.1:8000"
echo "     - API key: (value from infra/.env)"
echo ""
echo "  2. Start using open-terminal:"
echo "     - Clone repositories"
echo "     - Create branches"
echo "     - Implement changes"
echo ""
echo "  3. After each project, wipe workspace:"
echo "     ./infra/wipe-soft.sh   # Keep tools, remove project files"
echo "     ./infra/wipe-hard.sh   # Full reset"
echo ""
