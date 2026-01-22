#!/bin/bash
# Setup port forwarding for ArgoCD server
# This script sets up port forwarding to access ArgoCD UI locally

set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_PORT="8080"
ARGOCD_ALT_PORT="8081"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Setting up ArgoCD Port Forwarding ===${NC}"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

# Check if ArgoCD namespace exists
if ! kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist${NC}"
    echo "Please run: ./scripts/install-argocd.sh first"
    exit 1
fi

# Check if ArgoCD server service exists
if ! kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: ArgoCD server service not found${NC}"
    exit 1
fi

# Function to check if port is in use by kubectl port-forward
is_kubectl_port_forward() {
    local port=$1
    local pids=$(lsof -ti:${port} 2>/dev/null || echo "")
    if [ -z "$pids" ]; then
        return 1
    fi
    
    for pid in $pids; do
        if ps -p $pid -o command= 2>/dev/null | grep -q "kubectl.*port-forward.*argocd-server"; then
            return 0
        fi
    done
    return 1
}

# Function to kill existing kubectl port-forward on port
kill_existing_port_forward() {
    local port=$1
    local pids=$(lsof -ti:${port} 2>/dev/null || echo "")
    
    for pid in $pids; do
        if ps -p $pid -o command= 2>/dev/null | grep -q "kubectl.*port-forward.*argocd-server"; then
            echo -e "${YELLOW}Killing existing port-forward process (PID: $pid) on port ${port}...${NC}"
            kill $pid 2>/dev/null || true
            sleep 1
        fi
    done
}

# Function to setup port forwarding
setup_port_forward() {
    local port=$1
    local target_port=8080
    
    echo -e "${BLUE}Setting up port forwarding on localhost:${port}...${NC}"
    
    # Kill any existing kubectl port-forward on this port
    kill_existing_port_forward $port
    
    # Start port forwarding in background
    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" ${port}:${target_port} > /dev/null 2>&1 &
    local pid=$!
    
    # Wait a moment to check if it started successfully
    sleep 2
    
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Port forwarding started on port ${port} (PID: $pid)${NC}"
        echo $pid
        return 0
    else
        echo -e "${YELLOW}Warning: Port forwarding may have failed to start on port ${port}${NC}"
        return 1
    fi
}

# Try to setup port forwarding on primary port
if is_kubectl_port_forward $ARGOCD_PORT; then
    echo -e "${GREEN}Port forwarding already active on port ${ARGOCD_PORT}${NC}"
    PORT_FORWARD_PID=$(ps aux | grep "kubectl.*port-forward.*argocd-server.*${ARGOCD_PORT}" | grep -v grep | awk '{print $2}' | head -1)
    echo -e "${BLUE}Existing process PID: ${PORT_FORWARD_PID}${NC}"
else
    # Check if port is in use by other process
    if lsof -Pi :${ARGOCD_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}Port ${ARGOCD_PORT} is already in use by another process${NC}"
        echo -e "${BLUE}Trying alternative port ${ARGOCD_ALT_PORT}...${NC}"
        
        if is_kubectl_port_forward $ARGOCD_ALT_PORT; then
            echo -e "${GREEN}Port forwarding already active on port ${ARGOCD_ALT_PORT}${NC}"
            PORT_FORWARD_PID=$(ps aux | grep "kubectl.*port-forward.*argocd-server.*${ARGOCD_ALT_PORT}" | grep -v grep | awk '{print $2}' | head -1)
            echo -e "${BLUE}Existing process PID: ${PORT_FORWARD_PID}${NC}"
            ARGOCD_PORT=$ARGOCD_ALT_PORT
        else
            PORT_FORWARD_PID=$(setup_port_forward $ARGOCD_ALT_PORT)
            if [ $? -eq 0 ]; then
                ARGOCD_PORT=$ARGOCD_ALT_PORT
            else
                echo -e "${RED}Failed to set up port forwarding${NC}"
                exit 1
            fi
        fi
    else
        PORT_FORWARD_PID=$(setup_port_forward $ARGOCD_PORT)
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to set up port forwarding${NC}"
            exit 1
        fi
    fi
fi

echo ""
echo -e "${GREEN}=== Port Forwarding Setup Complete ===${NC}"
echo ""
echo "ArgoCD UI is accessible at:"
echo "  - http://localhost:${ARGOCD_PORT}"
echo "  - https://localhost:${ARGOCD_PORT}"
echo ""
if [ -n "$PORT_FORWARD_PID" ]; then
    echo "Port forwarding process PID: $PORT_FORWARD_PID"
    echo "To stop port forwarding, run:"
    echo "  kill $PORT_FORWARD_PID"
    echo "Or:"
    echo "  pkill -f 'kubectl port-forward.*argocd-server'"
    echo ""
fi
