#!/bin/bash
# Install ArgoCD on k3d cluster
# This script installs ArgoCD using the official stable manifests

set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="stable"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing ArgoCD ===${NC}"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

# Check if ArgoCD namespace already exists
if kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${YELLOW}ArgoCD namespace already exists${NC}"
    read -p "Do you want to reinstall ArgoCD? This will delete existing installation. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing ArgoCD installation...${NC}"
        kubectl delete namespace "$ARGOCD_NAMESPACE" --wait=true --timeout=60s || true
        sleep 5
    else
        echo -e "${GREEN}Using existing ArgoCD installation${NC}"
        echo "To get credentials, run: ./scripts/get-argocd-credentials.sh"
        exit 0
    fi
fi

# Create namespace
echo -e "${BLUE}Creating namespace '$ARGOCD_NAMESPACE'...${NC}"
kubectl create namespace "$ARGOCD_NAMESPACE"

# Install ArgoCD
echo -e "${BLUE}Installing ArgoCD from official manifests (version: $ARGOCD_VERSION)...${NC}"
kubectl apply -n "$ARGOCD_NAMESPACE" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo -e "${GREEN}✓ ArgoCD manifests applied${NC}"
echo ""

# Wait for ArgoCD server to be ready
echo -e "${BLUE}Waiting for ArgoCD server to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGOCD_NAMESPACE" || {
    echo -e "${YELLOW}Warning: ArgoCD server deployment timeout. Checking status...${NC}"
    kubectl get pods -n "$ARGOCD_NAMESPACE"
}

# Wait for all pods to be ready
echo -e "${BLUE}Waiting for all ArgoCD pods to be ready...${NC}"
kubectl wait --for=condition=ready pod --all -n "$ARGOCD_NAMESPACE" --timeout=300s || {
    echo -e "${YELLOW}Warning: Some pods may still be starting. Current status:${NC}"
    kubectl get pods -n "$ARGOCD_NAMESPACE"
}

# Apply LoadBalancer service
echo -e "${BLUE}Configuring LoadBalancer service for ArgoCD GUI...${NC}"
MANIFEST_DIR="$(dirname "$0")/../manifests"
if [ -f "${MANIFEST_DIR}/argocd-service.yaml" ]; then
    kubectl apply -f "${MANIFEST_DIR}/argocd-service.yaml"
else
    echo -e "${YELLOW}Warning: argocd-service.yaml not found, skipping LoadBalancer configuration${NC}"
fi

echo -e "${GREEN}✓ ArgoCD installation complete${NC}"
echo ""

# Show pod status
echo -e "${BLUE}ArgoCD Pod Status:${NC}"
kubectl get pods -n "$ARGOCD_NAMESPACE"
echo ""

# Show service status
echo -e "${BLUE}ArgoCD Service Status:${NC}"
kubectl get svc -n "$ARGOCD_NAMESPACE"
echo ""

# Set up port forwarding
ARGOCD_PORT="8080"
echo -e "${BLUE}Setting up port forwarding to localhost:${ARGOCD_PORT}...${NC}"

# Check if port is already in use
if lsof -Pi :${ARGOCD_PORT} -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}Port ${ARGOCD_PORT} is already in use${NC}"
    read -p "Do you want to kill the existing process and set up new port forwarding? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Killing process on port ${ARGOCD_PORT}...${NC}"
        lsof -ti:${ARGOCD_PORT} | xargs kill -9 2>/dev/null || true
        sleep 2
    else
        echo -e "${YELLOW}Skipping port forwarding setup${NC}"
        PORT_FORWARD_SETUP=false
    fi
fi

# Set up port forwarding in background
if [ "${PORT_FORWARD_SETUP:-true}" != "false" ]; then
    echo -e "${BLUE}Starting port forwarding (background process)...${NC}"
    
    # Start port forwarding in background
    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" ${ARGOCD_PORT}:8080 > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    
    # Wait a moment to check if it started successfully
    sleep 2
    
    if ps -p $PORT_FORWARD_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Port forwarding started (PID: $PORT_FORWARD_PID)${NC}"
        echo ""
        echo -e "${YELLOW}Note: Port forwarding is running in the background${NC}"
        echo "To stop port forwarding, run: kill $PORT_FORWARD_PID"
        echo "Or find and kill the process: lsof -ti:${ARGOCD_PORT} | xargs kill"
        echo ""
    else
        echo -e "${YELLOW}Warning: Port forwarding may have failed to start${NC}"
        echo "You can manually set it up with:"
        echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE ${ARGOCD_PORT}:8080"
        echo ""
    fi
fi

echo -e "${GREEN}=== ArgoCD Installation Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/get-argocd-credentials.sh"
echo "  2. Access ArgoCD GUI at: http://localhost:${ARGOCD_PORT}"
echo ""
if [ "${PORT_FORWARD_SETUP:-true}" != "false" ] && [ -n "$PORT_FORWARD_PID" ]; then
    echo "Port forwarding is active. To stop it later:"
    echo "  kill $PORT_FORWARD_PID"
    echo ""
fi