#!/bin/bash
# Cleanup script for ArgoCD PoC
# This script removes the k3d cluster and all related resources

set -e

CLUSTER_NAME="asciiartify-poc"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cleaning up ArgoCD PoC ===${NC}"
echo ""

# Check if cluster exists
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo -e "${YELLOW}Cluster '$CLUSTER_NAME' does not exist${NC}"
    exit 0
fi

# Confirm deletion
read -p "Are you sure you want to delete cluster '$CLUSTER_NAME'? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
fi

# Delete cluster
echo -e "${BLUE}Deleting k3d cluster '$CLUSTER_NAME'...${NC}"
k3d cluster delete "$CLUSTER_NAME"

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""
echo "Cluster '$CLUSTER_NAME' has been deleted."
echo ""
