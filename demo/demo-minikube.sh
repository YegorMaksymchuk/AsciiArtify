#!/bin/bash
# Demo script for minikube - Hello World deployment
# This script demonstrates minikube usage and port forwarding capabilities

set -e

echo "=== Minikube Demo: Hello World Deployment ==="
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
    echo -e "${YELLOW}Cleaning up minikube tunnel (if running)...${NC}"
    pkill -f "minikube tunnel" || true
}

trap cleanup EXIT

# Step 1: Start minikube cluster
echo -e "${BLUE}Step 1: Starting minikube cluster...${NC}"
echo -e "${YELLOW}Note: This may take 1-2 minutes with Docker driver, longer with VM drivers${NC}"
minikube start --driver=docker

echo -e "${GREEN}✓ Cluster started successfully${NC}"
echo ""

# Step 2: Verify cluster
echo -e "${BLUE}Step 2: Verifying cluster status...${NC}"
kubectl cluster-info
kubectl get nodes
echo ""

# Step 3: Enable ingress addon (required for Ingress to work)
echo -e "${BLUE}Step 3: Enabling ingress addon...${NC}"
minikube addons enable ingress
echo -e "${GREEN}✓ Ingress addon enabled${NC}"
echo ""

# Step 4: Deploy Hello World
echo -e "${BLUE}Step 4: Deploying Hello World application...${NC}"
kubectl create deployment hello-world --image=nginx:latest
kubectl wait --for=condition=available --timeout=60s deployment/hello-world
echo -e "${GREEN}✓ Deployment created${NC}"
echo ""

# Step 5: Expose service
echo -e "${BLUE}Step 5: Exposing service as LoadBalancer...${NC}"
kubectl expose deployment hello-world \
  --type=LoadBalancer \
  --port=80 \
  --target-port=80 \
  --name=hello-world-service
echo -e "${GREEN}✓ Service exposed${NC}"
echo ""

# Step 6: Wait for service to be ready
echo -e "${BLUE}Step 6: Waiting for service to be ready...${NC}"
sleep 5
kubectl get pods
kubectl get svc
echo ""

# Step 7: Access via minikube service (Method 1)
echo -e "${BLUE}Step 7: Accessing application via minikube service...${NC}"
echo -e "${YELLOW}Method 1: Using 'minikube service' command${NC}"
echo -e "${YELLOW}This will open the service URL in your browser...${NC}"
echo ""
echo -e "${GREEN}Service URL:${NC}"
minikube service hello-world-service --url
echo ""
echo -e "${YELLOW}Testing with curl...${NC}"
SERVICE_URL=$(minikube service hello-world-service --url)
curl -s "$SERVICE_URL" | head -n 5
echo ""
echo -e "${GREEN}✓ Application is accessible${NC}"
echo ""

# Step 8: Start minikube tunnel for LoadBalancer (Method 2)
echo -e "${BLUE}Step 8: Starting minikube tunnel for LoadBalancer access...${NC}"
echo -e "${YELLOW}Note: This runs in the background and routes LoadBalancer services${NC}"
minikube tunnel &
TUNNEL_PID=$!
sleep 10  # Wait for tunnel to establish

# Get the external IP
echo -e "${YELLOW}Waiting for LoadBalancer to get external IP...${NC}"
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc hello-world-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    sleep 2
done

if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}✓ LoadBalancer external IP: $EXTERNAL_IP${NC}"
    echo -e "${YELLOW}Testing access via LoadBalancer...${NC}"
    curl -s "http://$EXTERNAL_IP" | head -n 5
    echo ""
    echo -e "${GREEN}✓ Application accessible via LoadBalancer at http://$EXTERNAL_IP${NC}"
else
    echo -e "${YELLOW}⚠ LoadBalancer IP not assigned yet. This may take longer.${NC}"
    echo -e "${YELLOW}You can check with: kubectl get svc hello-world-service${NC}"
fi
echo ""

# Step 9: Create Ingress example
echo -e "${BLUE}Step 9: Creating Ingress example...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
spec:
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

# Get minikube IP for ingress
MINIKUBE_IP=$(minikube ip)
echo -e "${GREEN}Minikube IP: $MINIKUBE_IP${NC}"
echo -e "${YELLOW}To access via Ingress, add to /etc/hosts:${NC}"
echo -e "${YELLOW}  $MINIKUBE_IP hello.local${NC}"
echo ""

# Test ingress if /etc/hosts is configured
if grep -q "hello.local" /etc/hosts 2>/dev/null; then
    echo -e "${BLUE}Testing Ingress access...${NC}"
    curl -s http://hello.local | head -n 5
    echo ""
    echo -e "${GREEN}✓ Ingress is accessible${NC}"
else
    echo -e "${YELLOW}Note: Add '$MINIKUBE_IP hello.local' to /etc/hosts to test Ingress${NC}"
    echo -e "${YELLOW}Then run: curl http://hello.local${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}=== Demo Complete ===${NC}"
echo ""
echo "Summary:"
echo "  - Cluster started (may take 1-2 minutes)"
echo "  - Application deployed and accessible"
echo "  - LoadBalancer accessible via minikube tunnel"
echo "  - Ingress addon enabled and configured"
echo ""
echo "Access points:"
echo "  - Service URL: $(minikube service hello-world-service --url 2>/dev/null || echo 'Use: minikube service hello-world-service --url')"
if [ -n "$EXTERNAL_IP" ]; then
    echo "  - LoadBalancer: http://$EXTERNAL_IP"
fi
echo "  - Ingress: http://hello.local (requires /etc/hosts entry: $MINIKUBE_IP hello.local)"
echo ""
echo "Important notes:"
echo "  - Minikube tunnel is running in background (PID: $TUNNEL_PID)"
echo "  - Stop tunnel with: pkill -f 'minikube tunnel'"
echo "  - Or it will be stopped automatically when script exits"
echo ""
echo "To clean up, run:"
echo "  pkill -f 'minikube tunnel'  # Stop tunnel"
echo "  minikube stop               # Stop cluster"
echo "  minikube delete             # Delete cluster (optional)"
