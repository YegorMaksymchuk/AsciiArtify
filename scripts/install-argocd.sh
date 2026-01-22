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

echo -e "${GREEN}=== ArgoCD Installation Complete ===${NC}"
echo ""

# Set up port forwarding
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/setup-argocd-port-forward.sh" ]; then
    echo -e "${BLUE}Setting up port forwarding...${NC}"
    "${SCRIPT_DIR}/setup-argocd-port-forward.sh"
else
    echo -e "${YELLOW}Warning: setup-argocd-port-forward.sh not found${NC}"
    echo "You can manually set up port forwarding with:"
    echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:8080"
    echo ""
fi

echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/get-argocd-credentials.sh"
echo "  2. Access ArgoCD GUI at: http://localhost:8080 (or the port shown above)"
echo ""