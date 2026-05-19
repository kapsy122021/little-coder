#!/bin/bash
# Unified Little-Coder entrypoint
# Manages both little-coder (Node.js) and terminal-service (Python/Uvicorn) under supervisord

set -e

echo "🚀 Starting unified Little-Coder container..."
echo "================================================"
echo ""
echo "Processes managed by supervisord:"
echo "  • terminal-service  (Python/Uvicorn) → localhost:8000"
echo "  • little-coder      (Node.js)        → localhost:3000"
echo ""
echo "Environment:"
echo "  OPEN_TERMINAL_API_KEY: ${OPEN_TERMINAL_API_KEY:-(not set)}"
echo ""

# Ensure API key is set
if [ -z "$OPEN_TERMINAL_API_KEY" ]; then
    echo "⚠️  WARNING: OPEN_TERMINAL_API_KEY is not set!"
    echo "   Setting to empty for compatibility."
    export OPEN_TERMINAL_API_KEY=""
fi

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
