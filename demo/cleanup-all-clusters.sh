#!/bin/bash
# Cleanup script for k3d, minikube, and kind clusters
# This script checks for existing clusters and deletes all of them

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Kubernetes Cluster Cleanup Script ===${NC}"
echo ""

# Track if any clusters were found
CLUSTERS_FOUND=0

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cleanup k3d clusters
cleanup_k3d() {
    if command_exists k3d; then
        echo -e "${BLUE}Checking for k3d clusters...${NC}"
        K3D_CLUSTERS=$(k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' || echo "")
        
        if [ -z "$K3D_CLUSTERS" ]; then
            echo -e "${YELLOW}  No k3d clusters found${NC}"
        else
            CLUSTERS_FOUND=1
            echo -e "${GREEN}  Found k3d clusters:${NC}"
            k3d cluster list
            
            echo -e "${YELLOW}  Deleting all k3d clusters...${NC}"
            for cluster in $K3D_CLUSTERS; do
                echo -e "    Deleting cluster: ${cluster}"
                k3d cluster delete "$cluster" 2>/dev/null || true
            done
            
            # Also try to delete all clusters at once (k3d supports this)
            k3d cluster delete --all 2>/dev/null || true
            
            echo -e "${GREEN}  ✓ All k3d clusters deleted${NC}"
        fi
    else
        echo -e "${YELLOW}k3d not installed, skipping...${NC}"
    fi
    echo ""
}

# Cleanup minikube clusters
cleanup_minikube() {
    if command_exists minikube; then
        echo -e "${BLUE}Checking for minikube clusters...${NC}"
        
        # Check if minikube cluster exists
        if minikube status >/dev/null 2>&1; then
            CLUSTERS_FOUND=1
            echo -e "${GREEN}  Found minikube cluster${NC}"
            minikube status
            
            # Stop tunnel if running
            echo -e "${YELLOW}  Stopping minikube tunnel (if running)...${NC}"
            pkill -f "minikube tunnel" 2>/dev/null || true
            
            # Stop the cluster
            echo -e "${YELLOW}  Stopping minikube cluster...${NC}"
            minikube stop 2>/dev/null || true
            
            # Delete the cluster
            echo -e "${YELLOW}  Deleting minikube cluster...${NC}"
            minikube delete 2>/dev/null || true
            
            echo -e "${GREEN}  ✓ Minikube cluster deleted${NC}"
        else
            echo -e "${YELLOW}  No minikube cluster found${NC}"
        fi
        
        # Also check for any stopped clusters and clean them up
        if minikube status --profile=* >/dev/null 2>&1; then
            echo -e "${YELLOW}  Cleaning up any remaining minikube profiles...${NC}"
            minikube delete --all 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}minikube not installed, skipping...${NC}"
    fi
    echo ""
}

# Cleanup kind clusters
cleanup_kind() {
    if command_exists kind; then
        echo -e "${BLUE}Checking for kind clusters...${NC}"
        KIND_CLUSTERS=$(kind get clusters 2>/dev/null || echo "")
        
        if [ -z "$KIND_CLUSTERS" ]; then
            echo -e "${YELLOW}  No kind clusters found${NC}"
        else
            CLUSTERS_FOUND=1
            echo -e "${GREEN}  Found kind clusters:${NC}"
            kind get clusters
            
            echo -e "${YELLOW}  Stopping port-forward processes...${NC}"
            pkill -f "kubectl port-forward" 2>/dev/null || true
            
            echo -e "${YELLOW}  Deleting all kind clusters...${NC}"
            for cluster in $KIND_CLUSTERS; do
                echo -e "    Deleting cluster: ${cluster}"
                kind delete cluster --name "$cluster" 2>/dev/null || true
            done
            
            echo -e "${GREEN}  ✓ All kind clusters deleted${NC}"
        fi
    else
        echo -e "${YELLOW}kind not installed, skipping...${NC}"
    fi
    echo ""
}

# Cleanup kubectl port-forward processes
cleanup_port_forwards() {
    echo -e "${BLUE}Checking for kubectl port-forward processes...${NC}"
    PORT_FORWARDS=$(pgrep -f "kubectl port-forward" 2>/dev/null || echo "")
    
    if [ -z "$PORT_FORWARDS" ]; then
        echo -e "${YELLOW}  No port-forward processes found${NC}"
    else
        echo -e "${YELLOW}  Stopping kubectl port-forward processes...${NC}"
        pkill -f "kubectl port-forward" 2>/dev/null || true
        sleep 1
        echo -e "${GREEN}  ✓ Port-forward processes stopped${NC}"
    fi
    echo ""
}

# Cleanup /etc/hosts entries
cleanup_hosts() {
    echo -e "${BLUE}Checking /etc/hosts for demo entries...${NC}"
    
    if [ -f /etc/hosts ]; then
        # Check for hello.local entry
        if grep -q "hello.local" /etc/hosts 2>/dev/null; then
            echo -e "${YELLOW}  Found hello.local entry in /etc/hosts${NC}"
            echo -e "${YELLOW}  Removing hello.local entry...${NC}"
            
            # macOS
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sudo sed -i '' '/hello.local/d' /etc/hosts 2>/dev/null || true
            # Linux
            else
                sudo sed -i '/hello.local/d' /etc/hosts 2>/dev/null || true
            fi
            
            echo -e "${GREEN}  ✓ hello.local entry removed${NC}"
        else
            echo -e "${YELLOW}  No demo entries found in /etc/hosts${NC}"
        fi
    else
        echo -e "${YELLOW}  /etc/hosts file not found${NC}"
    fi
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}Starting cleanup process...${NC}"
    echo ""
    
    # Cleanup clusters
    cleanup_k3d
    cleanup_minikube
    cleanup_kind
    
    # Cleanup related processes
    cleanup_port_forwards
    
    # Cleanup /etc/hosts
    cleanup_hosts
    
    # Summary
    echo -e "${BLUE}=== Cleanup Summary ===${NC}"
    if [ $CLUSTERS_FOUND -eq 0 ]; then
        echo -e "${GREEN}✓ No clusters found - system is clean${NC}"
    else
        echo -e "${GREEN}✓ All clusters have been deleted${NC}"
    fi
    echo ""
    
    # Final verification
    echo -e "${BLUE}Final verification:${NC}"
    
    if command_exists k3d; then
        K3D_COUNT=$(k3d cluster list --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        echo -e "  k3d clusters: ${K3D_COUNT}"
    fi
    
    if command_exists minikube; then
        if minikube status >/dev/null 2>&1; then
            echo -e "  minikube: ${RED}Still running${NC}"
        else
            echo -e "  minikube: ${GREEN}No cluster${NC}"
        fi
    fi
    
    if command_exists kind; then
        KIND_COUNT=$(kind get clusters 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        echo -e "  kind clusters: ${KIND_COUNT}"
    fi
    
    echo ""
    echo -e "${GREEN}=== Cleanup Complete ===${NC}"
}

# Run main function
main
