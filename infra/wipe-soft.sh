#!/bin/bash
# Soft wipe: clear project workspace while preserving tools and caches

set -e

CONTAINER_NAME="little-coder"

if ! docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container '$CONTAINER_NAME' is not running."
    exit 1
fi

echo "🧹 Performing soft wipe: clearing project workspace..."
docker exec -it "$CONTAINER_NAME" sh -lc 'rm -rf /home/user/projects/* && echo "✅ Workspace cleared"'

echo ""
echo "✅ Soft wipe complete. Tools and caches preserved."
echo "   Ready for next project."


