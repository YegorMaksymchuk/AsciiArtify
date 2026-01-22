#!/bin/bash
# Demo script for ArgoCD Application deployment
# This script demonstrates ArgoCD GitOps workflow with go-demo-app
# Records demo using asciinema

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_NAMESPACE="argocd"
APP_NAMESPACE="demo"
APP_NAME="go-demo-app"
APP_POD="app"
APP_PORT_LOCAL="8082"
APP_PORT_CONTAINER="8080"
DEMO_FILE="demo-argocd-app.cast"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== ArgoCD Application Demo ===${NC}"
echo ""
echo "This demo will show:"
echo "  1. ArgoCD status and access"
echo "  2. Application sync status"
echo "  3. Deployed resources"
echo "  4. Application API testing"
echo ""

# Check if asciinema is installed
if ! command -v asciinema &> /dev/null; then
    echo -e "${RED}Error: asciinema is not installed${NC}"
    echo "Install it with: brew install asciinema"
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

# Check if ArgoCD is installed
if ! kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist${NC}"
    echo "Please install ArgoCD first: ./scripts/install-argocd.sh"
    exit 1
fi

# Check if Application exists
if ! kubectl get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: Application '$APP_NAME' does not exist${NC}"
    echo "Please create the Application first"
    exit 1
fi

# Change to script directory
cd "$SCRIPT_DIR"

# Path to commands script
COMMANDS_SCRIPT="$SCRIPT_DIR/demo-argocd-app-commands.sh"

# Check if commands script exists
if [ ! -f "$COMMANDS_SCRIPT" ]; then
    echo -e "${RED}Error: Commands script not found: $COMMANDS_SCRIPT${NC}"
    exit 1
fi

# Make sure commands script is executable
chmod +x "$COMMANDS_SCRIPT"

echo -e "${GREEN}Starting demo recording...${NC}"
echo "Press Ctrl+C to stop recording"
echo ""
sleep 2

# Start asciinema recording with the commands script
asciinema rec "$DEMO_FILE" -c "$COMMANDS_SCRIPT"

echo ""
echo -e "${GREEN}Demo recording completed!${NC}"
echo "Recording saved to: $SCRIPT_DIR/$DEMO_FILE"
echo ""
echo "To play the recording:"
echo "  asciinema play $SCRIPT_DIR/$DEMO_FILE"
echo ""
echo "To upload to asciinema.org:"
echo "  asciinema upload $SCRIPT_DIR/$DEMO_FILE"
echo ""
