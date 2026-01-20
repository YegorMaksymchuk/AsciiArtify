#!/bin/bash
# Setup k3d cluster for ArgoCD PoC
# This script creates a k3d cluster with port forwarding for ArgoCD GUI access

set -e

CLUSTER_NAME="asciiartify-poc"
ARGOCD_PORT="8080"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Setting up k3d cluster for ArgoCD PoC ===${NC}"
echo ""

# Check if k3d is installed
if ! command -v k3d &> /dev/null; then
    echo -e "${RED}Error: k3d is not installed${NC}"
    echo "Please install k3d:"
    echo "  macOS: brew install k3d"
    echo "  Linux: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Check if cluster already exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo -e "${YELLOW}Cluster '$CLUSTER_NAME' already exists${NC}"
    read -p "Do you want to delete it and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing cluster...${NC}"
        k3d cluster delete "$CLUSTER_NAME"
    else
        echo -e "${GREEN}Using existing cluster${NC}"
        kubectl config use-context "k3d-$CLUSTER_NAME"
        exit 0
    fi
fi

# Create k3d cluster with port forwarding for ArgoCD
echo -e "${BLUE}Creating k3d cluster '$CLUSTER_NAME'...${NC}"
k3d cluster create "$CLUSTER_NAME" \
  --port "${ARGOCD_PORT}:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait

echo -e "${GREEN}✓ Cluster created successfully${NC}"
echo ""

# Set kubectl context
kubectl config use-context "k3d-$CLUSTER_NAME"

# Verify cluster
echo -e "${BLUE}Verifying cluster status...${NC}"
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

echo -e "${GREEN}=== Cluster Setup Complete ===${NC}"
echo ""
echo "Cluster Name: $CLUSTER_NAME"
echo "ArgoCD will be accessible on: http://localhost:${ARGOCD_PORT}"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/install-argocd.sh"
echo "  2. Run: ./scripts/get-argocd-credentials.sh"
echo ""
