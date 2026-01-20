#!/bin/bash
# Demo script for k3d - Hello World deployment
# This script demonstrates the ease of use and port forwarding capabilities of k3d

set -e

echo "=== k3d Demo: Hello World Deployment ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Create cluster with port forwarding
echo -e "${BLUE}Step 1: Creating k3d cluster with port forwarding...${NC}"
k3d cluster create demo-cluster \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait

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

# Step 4: Expose service
echo -e "${BLUE}Step 4: Exposing service as LoadBalancer...${NC}"
kubectl expose deployment hello-world \
  --type=LoadBalancer \
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

# Step 6: Test access
echo -e "${BLUE}Step 6: Testing access to application...${NC}"
echo -e "${YELLOW}Accessing http://localhost:8080${NC}"
curl -s http://localhost:8080 | head -n 5
echo ""
echo -e "${GREEN}✓ Application is accessible on http://localhost:8080${NC}"
echo ""

# Step 7: Create Ingress example
echo -e "${BLUE}Step 7: Creating Ingress example...${NC}"
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

# Summary
echo -e "${GREEN}=== Demo Complete ===${NC}"
echo ""
echo "Summary:"
echo "  - Cluster created in seconds"
echo "  - Application deployed and accessible"
echo "  - Port forwarding works automatically"
echo "  - LoadBalancer and Ingress ready to use"
echo ""
echo "Access points:"
echo "  - http://localhost:8080 (LoadBalancer)"
echo "  - http://hello.local (Ingress - add to /etc/hosts)"
echo ""
echo "To clean up, run:"
echo "  k3d cluster delete demo-cluster"
