#!/bin/bash
# Get ArgoCD admin credentials
# This script retrieves the initial admin password for ArgoCD

set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_USERNAME="admin"
SECRET_NAME="argocd-initial-admin-secret"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ArgoCD Credentials ===${NC}"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist${NC}"
    echo "Please run: ./scripts/install-argocd.sh"
    exit 1
fi

# Wait for secret to be created (it's created by ArgoCD operator)
echo -e "${BLUE}Waiting for ArgoCD secret to be created...${NC}"
for i in {1..30}; do
    if kubectl get secret "$SECRET_NAME" -n "$ARGOCD_NAMESPACE" &> /dev/null; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Secret '$SECRET_NAME' not found after 30 seconds${NC}"
        echo "ArgoCD may still be initializing. Please wait and try again."
        exit 1
    fi
    sleep 1
done

# Get password from secret
PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret "$SECRET_NAME" -o jsonpath="{.data.password}" | base64 -d)

if [ -z "$PASSWORD" ]; then
    echo -e "${RED}Error: Could not retrieve password${NC}"
    exit 1
fi

# Get service information
echo -e "${BLUE}Checking ArgoCD service...${NC}"
SERVICE_INFO=$(kubectl -n "$ARGOCD_NAMESPACE" get svc argocd-server -o jsonpath='{.spec.type}' 2>/dev/null || echo "ClusterIP")

# Display credentials
echo ""
echo -e "${GREEN}=== ArgoCD Access Information ===${NC}"
echo ""
echo "Username: $ARGOCD_USERNAME"
echo "Password: $PASSWORD"
echo ""

if [ "$SERVICE_INFO" = "LoadBalancer" ]; then
    EXTERNAL_IP=$(kubectl -n "$ARGOCD_NAMESPACE" get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        echo "ArgoCD GUI URL: http://${EXTERNAL_IP}:8080"
    else
        echo "ArgoCD GUI URL: http://localhost:8080 (via port forwarding)"
        echo ""
        echo "To set up port forwarding, run:"
        echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:8080"
    fi
else
    echo "ArgoCD GUI URL: http://localhost:8080"
    echo ""
    echo "To access ArgoCD GUI, set up port forwarding:"
    echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:8080"
fi

echo ""
echo -e "${YELLOW}Note: Save these credentials securely. The initial admin password is only shown once.${NC}"
echo ""
echo "To login via CLI:"
echo "  argocd login localhost:8080 --username $ARGOCD_USERNAME --password '$PASSWORD'"
echo ""
