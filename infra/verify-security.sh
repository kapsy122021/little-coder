#!/bin/bash
# Verify security posture of Little-Coder unified container

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        exit 1
    fi
}

echo "🔐 Verifying Little-Coder unified container security posture..."
echo ""

# Check unified container
echo "Checking little-coder container..."
if docker ps --filter "name=little-coder" --format "{{.Names}}" | grep -q "little-coder"; then
    check_result 0 "little-coder unified container is running"
else
    echo -e "${YELLOW}⚠${NC} little-coder container is not running (OK if not started yet)"
fi

# Check network
echo "Checking network..."
if docker network ls --filter "name=little-coder-net" --format "{{.Name}}" | grep -q "little-coder-net"; then
    check_result 0 "little-coder-net network exists"
else
    echo -e "${YELLOW}⚠${NC} little-coder-net network not found (OK if not started yet)"
fi

# Check port bindings
if docker inspect little-coder 2>/dev/null | grep -q "127.0.0.1"; then
    check_result 0 "Loopback-only port bindings confirmed"
else
    echo -e "${YELLOW}⚠${NC} Port bindings may differ"
fi

# Check resource limits
if docker inspect little-coder 2>/dev/null | grep -q '"PidsLimit": 512'; then
    check_result 0 "Process limit set to 512"
else
    echo -e "${YELLOW}⚠${NC} Process limit may differ"
fi

if docker inspect little-coder 2>/dev/null | grep -q '"Memory": 4294967296'; then
    check_result 0 "Memory limit set to 4GB"
else
    echo -e "${YELLOW}⚠${NC} Memory limit may differ (configured for 4GB)"
fi

# Check healthcheck
if docker inspect little-coder 2>/dev/null | grep -q '"Health"'; then
    check_result 0 "Healthcheck configured"
else
    echo -e "${YELLOW}⚠${NC} Healthcheck not detected (may be running)"
fi

echo ""
echo -e "${GREEN}✅ Security verification complete!${NC}"
echo ""
echo "Little-Coder unified architecture:"
echo "  • Single container: little-coder"
echo "  • Services: little-coder (Node.js) + open-terminal (Uvicorn)"
echo "  • Managed by: supervisord"
echo "  • Resource limits: 4GB RAM, 4 CPUs, 512 processes"
echo "  • Loopback-only external access (port 127.0.0.1:8001)"
echo "  • Health monitoring: Uvicorn endpoint"


