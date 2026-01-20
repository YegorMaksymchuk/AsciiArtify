#!/bin/bash
# Demo script for kind - Hello World deployment
# This script demonstrates kind usage and port forwarding capabilities

set -e

echo "=== Kind Demo: Hello World Deployment ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up port-forward processes (if running)...${NC}"
    pkill -f "kubectl port-forward" || true
}

trap cleanup EXIT

# Step 1: Create kind cluster
echo -e "${BLUE}Step 1: Creating kind cluster...${NC}"
echo -e "${YELLOW}Note: This typically takes 30-60 seconds${NC}"
kind create cluster --name demo-cluster

echo -e "${GREEN}✓ Cluster created successfully${NC}"
echo ""

# Step 2: Verify cluster
echo -e "${BLUE}Step 2: Verifying cluster status...${NC}"
kubectl cluster-info
kubectl get nodes
echo ""

# Step 3: Deploy Hello World
echo -e "${BLUE}Step 3: Deploying Hello World application...${NC}"
kubectl create deployment hello-world --image=nginx:latest
kubectl wait --for=condition=available --timeout=60s deployment/hello-world
echo -e "${GREEN}✓ Deployment created${NC}"
echo ""

# Step 4: Expose service as NodePort (Method 1)
echo -e "${BLUE}Step 4: Exposing service as NodePort...${NC}"
echo -e "${YELLOW}Note: Kind doesn't have built-in LoadBalancer, so we use NodePort${NC}"
kubectl expose deployment hello-world \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --name=hello-world-service
echo -e "${GREEN}✓ Service exposed${NC}"
echo ""

# Step 5: Wait for service to be ready
echo -e "${BLUE}Step 5: Waiting for service to be ready...${NC}"
sleep 5
kubectl get pods
kubectl get svc
echo ""

# Step 6: Get NodePort and access via Docker port mapping
echo -e "${BLUE}Step 6: Accessing application via NodePort...${NC}"
NODEPORT=$(kubectl get svc hello-world-service -o jsonpath='{.spec.ports[0].nodePort}')
echo -e "${GREEN}NodePort: $NODEPORT${NC}"

# Get the kind node container name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo -e "${GREEN}Node name: $NODE_NAME${NC}"

# Get the Docker container name for the kind node
CONTAINER_NAME="demo-cluster-control-plane"
echo -e "${YELLOW}Accessing via Docker port mapping...${NC}"

# Check if we can access via localhost (if Docker port mapping is configured)
# For kind, we need to use docker port or kubectl port-forward
echo -e "${YELLOW}Method 1: Using kubectl port-forward (recommended)${NC}"
echo ""
echo -e "${BLUE}Starting port-forward in background...${NC}"
kubectl port-forward svc/hello-world-service 8080:80 &
PORT_FORWARD_PID=$!
sleep 3

echo -e "${YELLOW}Testing access via port-forward (localhost:8080)...${NC}"
curl -s http://localhost:8080 | head -n 5
echo ""
echo -e "${GREEN}✓ Application is accessible on http://localhost:8080${NC}"
echo ""

# Step 7: Alternative - Access via Docker exec (direct node access)
echo -e "${BLUE}Step 7: Alternative access method - Direct node access...${NC}"
echo -e "${YELLOW}Method 2: Accessing via Docker exec to the node${NC}"
echo -e "${YELLOW}This demonstrates direct access to the kind node...${NC}"
NODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
if [ -n "$NODE_IP" ]; then
    echo -e "${GREEN}Node IP: $NODE_IP${NC}"
    echo -e "${YELLOW}You can access via: curl http://$NODE_IP:$NODEPORT${NC}"
    echo -e "${YELLOW}Or use Docker port mapping: docker port $CONTAINER_NAME${NC}"
else
    echo -e "${YELLOW}Note: Node IP not available, using port-forward method${NC}"
fi
echo ""

# Step 8: Install Ingress Controller (optional but recommended)
echo -e "${BLUE}Step 8: Installing Ingress Controller (ingress-nginx)...${NC}"
echo -e "${YELLOW}Note: Kind doesn't include Ingress Controller by default${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo -e "${YELLOW}Waiting for Ingress Controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo -e "${GREEN}✓ Ingress Controller installed${NC}"
echo ""

# Step 9: Create Ingress example
echo -e "${BLUE}Step 9: Creating Ingress example...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world-service
            port:
              number: 80
EOF
echo -e "${GREEN}✓ Ingress created${NC}"
echo ""

# Wait for ingress to be ready
echo -e "${BLUE}Waiting for Ingress to be ready...${NC}"
sleep 10
kubectl get ingress
echo ""

# Get ingress controller service details
INGRESS_SERVICE=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
echo -e "${GREEN}Ingress Controller NodePort: $INGRESS_SERVICE${NC}"

# Port forward for ingress
echo -e "${BLUE}Setting up port-forward for Ingress...${NC}"
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 &
INGRESS_PF_PID=$!
sleep 3

echo -e "${YELLOW}To access via Ingress, add to /etc/hosts:${NC}"
echo -e "${YELLOW}  127.0.0.1 hello.local${NC}"
echo ""

# Test ingress if /etc/hosts is configured
if grep -q "hello.local" /etc/hosts 2>/dev/null; then
    echo -e "${BLUE}Testing Ingress access...${NC}"
    curl -s -H "Host: hello.local" http://localhost:8081 | head -n 5
    echo ""
    echo -e "${GREEN}✓ Ingress is accessible${NC}"
else
    echo -e "${YELLOW}Note: Add '127.0.0.1 hello.local' to /etc/hosts to test Ingress${NC}"
    echo -e "${YELLOW}Then run: curl -H 'Host: hello.local' http://localhost:8081${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}=== Demo Complete ===${NC}"
echo ""
echo "Summary:"
echo "  - Cluster created in 30-60 seconds"
echo "  - Application deployed and accessible"
echo "  - NodePort service configured"
echo "  - Port-forwarding configured for easy access"
echo "  - Ingress Controller installed and configured"
echo ""
echo "Access points:"
echo "  - Port-forward (Service): http://localhost:8080"
echo "  - Port-forward (Ingress): http://localhost:8081"
if [ -n "$NODE_IP" ] && [ -n "$NODEPORT" ]; then
    echo "  - Direct node access: http://$NODE_IP:$NODEPORT"
fi
echo "  - Ingress: http://hello.local (requires /etc/hosts entry: 127.0.0.1 hello.local)"
echo ""
echo "Important notes:"
echo "  - Port-forward processes are running in background"
echo "  - Service port-forward PID: $PORT_FORWARD_PID"
echo "  - Ingress port-forward PID: $INGRESS_PF_PID"
echo "  - Stop port-forwards with: pkill -f 'kubectl port-forward'"
echo "  - Or they will be stopped automatically when script exits"
echo ""
echo "To clean up, run:"
echo "  pkill -f 'kubectl port-forward'  # Stop port-forwards"
echo "  kind delete cluster --name demo-cluster  # Delete cluster"
