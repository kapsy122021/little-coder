#!/bin/bash
# Soft wipe: clear the open-terminal workspace while preserving tools and caches.
# The workspace lives in the open-terminal container (that's what little-coder
# operates against via the OT* tools); little-coder's own filesystem is read-only
# from the agent's perspective and never holds project work.

set -e

CONTAINER_NAME="open-terminal"

if ! docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container '$CONTAINER_NAME' is not running."
    exit 1
fi

echo "🧹 Performing soft wipe: clearing project workspace..."
docker exec -it "$CONTAINER_NAME" sh -lc 'rm -rf /home/user/projects/* && echo "✅ Workspace cleared"'

echo ""
echo "✅ Soft wipe complete. Tools and caches preserved."
echo "   Ready for next project."


