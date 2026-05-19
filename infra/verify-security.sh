#!/bin/bash
# Verify security posture and isolation

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

echo "🔐 Verifying security posture and isolation..."
echo ""

# Check open-terminal
echo "Checking open-terminal container..."
if docker ps --filter "name=open-terminal" --format "{{.Names}}" | grep -q "open-terminal"; then
    check_result 0 "open-terminal container is running"
else
    echo -e "${YELLOW}⚠${NC} open-terminal is not running (OK if not started yet)"
fi

# Check docker socket NOT mounted
! docker inspect open-terminal 2>/dev/null | grep -q "docker.sock" && check_result 0 "No docker.sock mount in open-terminal" || (echo -e "${RED}✗${NC} docker.sock is mounted in open-terminal (SECURITY RISK)"; exit 1)

# Check read-only filesystem
docker inspect open-terminal 2>/dev/null | grep -q '"ReadonlyRootfs": true' && check_result 0 "open-terminal uses read-only root filesystem" || (echo -e "${RED}✗${NC} read-only filesystem not enabled"; exit 1)

# Check tmpfs mounts
docker inspect open-terminal 2>/dev/null | grep -q '"Mode": "/tmp"' && check_result 0 "open-terminal uses tmpfs for /tmp" || (echo -e "${YELLOW}⚠${NC} tmpfs not detected (may be OK)")

# Check port binding
docker inspect open-terminal 2>/dev/null | grep -q "127.0.0.1" && check_result 0 "open-terminal bound to loopback (127.0.0.1) only" || (echo -e "${RED}✗${NC} Port not bound to loopback"; exit 1)

# Check cap_drop
docker inspect open-terminal 2>/dev/null | grep -q '"ALL"' && check_result 0 "All capabilities dropped from open-terminal" || (echo -e "${RED}✗${NC} Capabilities not fully dropped"; exit 1)

# Check security options
docker inspect open-terminal 2>/dev/null | grep -q "no-new-privileges" && check_result 0 "no-new-privileges enabled on open-terminal" || (echo -e "${RED}✗${NC} no-new-privileges not set"; exit 1)

# Check network isolation
if docker network ls --filter "name=ot-net" --format "{{.Name}}" | grep -q "ot-net"; then
    check_result 0 "open-terminal network (ot-net) exists"
else
    echo -e "${YELLOW}⚠${NC} open-terminal network not found (OK if not started yet)"
fi

if docker network ls --filter "name=lc-net" --format "{{.Name}}" | grep -q "lc-net"; then
    check_result 0 "little-coder network (lc-net) exists"
fi

# Check resource limits
docker inspect open-terminal 2>/dev/null | grep -q '"PidsLimit": 256' && check_result 0 "Process limit set to 256" || (echo -e "${YELLOW}⚠${NC} Process limit may differ")

docker inspect open-terminal 2>/dev/null | grep -q '"Memory": 2147483648' && check_result 0 "Memory limit set to 2GB" || (echo -e "${YELLOW}⚠${NC} Memory limit may differ")

echo ""
echo -e "${GREEN}✅ Security verification complete!${NC}"
echo ""
echo "Key security properties enforced:"
echo "  • No Docker socket exposure"
echo "  • Read-only root filesystem"
echo "  • All capabilities dropped"
echo "  • Loopback-only port binding"
echo "  • Isolated networks (ot-net / lc-net)"
echo "  • Resource limits applied"
echo "  • no-new-privileges flag set"
