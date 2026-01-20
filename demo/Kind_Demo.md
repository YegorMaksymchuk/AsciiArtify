# Kind Demonstration Guide

This document provides a detailed demonstration plan for showcasing kind capabilities, including cluster creation, application deployment, and port forwarding.

## Overview

This demonstration showcases kind's key features:
- **Fast cluster creation** (30-60 seconds)
- **Docker-in-Docker** technology
- **Standard Kubernetes** (100% compatibility)
- **CI/CD friendly** design
- **Multi-node cluster** support

## Prerequisites

Before running the demonstration, ensure you have the following installed:

- **Docker** - Required (kind runs Kubernetes in Docker containers)
- **kubectl** - Kubernetes command-line tool
- **kind** - Install via one of the following methods:
  ```bash
  # macOS (Homebrew)
  brew install kind
  
  # Linux/macOS (Binary)
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  
  # Windows (via Chocolatey)
  choco install kind
  
  # Verify installation
  kind --version
  ```

## Detailed Demo Plan

### Step 1: Create Kind Cluster

**Objective**: Demonstrate fast cluster creation using Docker-in-Docker.

**Command**:
```bash
kind create cluster --name demo-cluster
```

**What happens**:
- Creates a new kind cluster named `demo-cluster`
- Uses Docker-in-Docker to run Kubernetes nodes as containers
- Configures kubectl context automatically
- Cluster creation typically takes 30-60 seconds

**Expected Output**:
```
Creating cluster "demo-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.28.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-demo-cluster"
You can now use your cluster with:

kubectl cluster-info --context kind-demo-cluster
kubectl get nodes --context kind-demo-cluster

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```

**Key Points to Highlight**:
- ✅ Cluster created in 30-60 seconds
- ✅ Uses Docker-in-Docker technology
- ✅ Automatically configures kubectl context
- ✅ Standard Kubernetes (100% compatibility)

---

### Step 2: Verify Cluster Status

**Objective**: Confirm cluster is running and accessible.

**Commands**:
```bash
kubectl cluster-info
kubectl get nodes
```

**What happens**:
- `kubectl cluster-info` displays cluster endpoint and Kubernetes version
- `kubectl get nodes` shows cluster nodes and their status

**Expected Output**:
```
Kubernetes control plane is running at https://127.0.0.1:xxxxx
CoreDNS is running at https://127.0.0.1:xxxxx/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME                        STATUS   ROLES           AGE   VERSION
demo-cluster-control-plane   Ready    control-plane   1m    v1.28.0
```

**Key Points to Highlight**:
- ✅ Cluster is ready and node is in `Ready` state
- ✅ Uses standard Kubernetes (100% compatibility)
- ✅ Single command to verify status

---

### Step 3: Deploy Hello World Application

**Objective**: Deploy a simple nginx-based application to demonstrate deployment workflow.

**Command**:
```bash
kubectl create deployment hello-world --image=nginx:latest
kubectl wait --for=condition=available --timeout=60s deployment/hello-world
```

**What happens**:
- Creates a Deployment named `hello-world` using nginx:latest image
- `kubectl wait` ensures the deployment is ready before proceeding
- Pods are scheduled and started automatically

**Expected Output**:
```
deployment.apps/hello-world created
deployment.apps/hello-world condition met
```

**Key Points to Highlight**:
- ✅ Standard Kubernetes commands work identically
- ✅ Deployment created with single command
- ✅ Automatic pod scheduling and startup

---

### Step 4: Expose Service as NodePort

**Objective**: Demonstrate NodePort service type (kind doesn't have built-in LoadBalancer).

**Command**:
```bash
kubectl expose deployment hello-world \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --name=hello-world-service
```

**What happens**:
- Creates a Service of type `NodePort`
- Exposes port 80 on the service
- Maps to port 80 on the pods (target-port)
- Kubernetes assigns a random NodePort (30000-32767 range)

**Expected Output**:
```
service/hello-world-service exposed
```

**Key Points to Highlight**:
- ✅ Kind doesn't have built-in LoadBalancer (unlike k3d)
- ✅ NodePort is the standard way to expose services
- ✅ NodePort is assigned automatically by Kubernetes

---

### Step 5: Verify Deployment Status

**Objective**: Confirm pods and services are running correctly.

**Commands**:
```bash
sleep 5  # Allow time for service to be fully ready
kubectl get pods
kubectl get svc
```

**What happens**:
- `kubectl get pods` shows pod status and readiness
- `kubectl get svc` displays service configuration and NodePort

**Expected Output**:
```
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-7d4b8c9f6b-xxxxx   1/1     Running   0          30s

NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
hello-world-service    NodePort   10.96.x.x       <none>        80:3xxxx/TCP   10s
kubernetes             ClusterIP  10.96.0.1       <none>        443/TCP         1m
```

**Key Points to Highlight**:
- ✅ Pod is running and ready (1/1)
- ✅ Service has NodePort type
- ✅ NodePort number shown in PORT(S) column (e.g., 80:3xxxx/TCP)

---

### Step 6: Access via Port-Forward (Method 1 - Recommended)

**Objective**: Demonstrate kubectl port-forward for easy access.

**Command**:
```bash
kubectl port-forward svc/hello-world-service 8080:80
```

**What happens**:
- Creates a port-forward from localhost:8080 to service port 80
- Runs in foreground (use `&` to run in background)
- Routes traffic from local port to service

**Running in Background**:
```bash
kubectl port-forward svc/hello-world-service 8080:80 &
PORT_FORWARD_PID=$!
sleep 3
```

**Testing**:
```bash
curl -s http://localhost:8080 | head -n 5
```

**Expected Output**:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

**Key Points to Highlight**:
- ✅ Simple and reliable access method
- ✅ Works immediately without additional setup
- ✅ Standard kubectl command (works with any Kubernetes cluster)
- ✅ Must run continuously (background process)

---

### Step 7: Alternative Access - Direct Node Access (Method 2)

**Objective**: Demonstrate direct access to kind node via Docker.

**Commands**:
```bash
# Get NodePort
NODEPORT=$(kubectl get svc hello-world-service -o jsonpath='{.spec.ports[0].nodePort}')

# Get node container name
CONTAINER_NAME="demo-cluster-control-plane"

# Get node IP
NODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")
```

**What happens**:
- Retrieves the NodePort assigned to the service
- Gets the Docker container name for the kind node
- Extracts the IP address of the Docker container

**Testing**:
```bash
curl http://$NODE_IP:$NODEPORT
```

**Key Points to Highlight**:
- ✅ Direct access to the kind node
- ✅ Demonstrates Docker-in-Docker architecture
- ✅ Useful for debugging and understanding kind's internals
- ✅ Less convenient than port-forwarding

---

### Step 8: Install Ingress Controller

**Objective**: Install NGINX Ingress Controller (not included by default).

**Command**:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

**What happens**:
- Downloads and applies NGINX Ingress Controller manifest
- Creates namespace `ingress-nginx`
- Deploys Ingress Controller pods and services
- Configures for kind environment

**Wait for Controller to be Ready**:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

**Expected Output**:
```
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
...
pod/ingress-nginx-controller-xxxxx condition met
```

**Key Points to Highlight**:
- ✅ Ingress Controller must be installed manually (not included)
- ✅ Uses official NGINX Ingress Controller
- ✅ Takes 1-2 minutes to become ready
- ✅ Required for Ingress resources to work

---

### Step 9: Create Ingress Resource

**Objective**: Demonstrate Ingress functionality with installed controller.

**Command**:
```bash
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
```

**What happens**:
- Creates an Ingress resource for host-based routing
- NGINX Ingress Controller picks up the Ingress
- Routes traffic from `hello.local` to the `hello-world-service`
- Requires `ingressClassName: nginx` for NGINX controller

**Expected Output**:
```
ingress.networking.k8s.io/hello-world-ingress created
```

**Access via Ingress**:
```bash
# Port-forward Ingress Controller service
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 &
INGRESS_PF_PID=$!
sleep 3

# Add to /etc/hosts
echo "127.0.0.1 hello.local" | sudo tee -a /etc/hosts

# Test Ingress
curl -H "Host: hello.local" http://localhost:8081
```

**Key Points to Highlight**:
- ✅ Ingress Controller must be installed first
- ✅ Requires port-forwarding for access
- ✅ Requires /etc/hosts entry
- ✅ Supports host-based and path-based routing

---

## Demo Summary

### What Was Demonstrated

1. **Fast Cluster Creation**: Cluster created in 30-60 seconds
2. **Docker-in-Docker**: Kubernetes nodes run as Docker containers
3. **Standard Kubernetes**: 100% API compatibility
4. **NodePort Services**: Standard way to expose services
5. **Port-Forwarding**: Easy access via kubectl port-forward
6. **Ingress Controller**: Manual installation required
7. **Multi-Access Methods**: Port-forward, direct node access, and Ingress

### Access Points

After completing the demo, the application is accessible via:

- **Port-Forward (Service)**: `http://localhost:8080`
- **Port-Forward (Ingress)**: `http://localhost:8081`
- **Direct Node Access**: `http://<node-ip>:<nodeport>`
- **Ingress**: `http://hello.local` (requires /etc/hosts entry and port-forward)

### Key Characteristics Demonstrated

| Feature | Kind | k3d | Minikube |
|---------|------|-----|----------|
| Cluster Creation Time | 30-60 sec | 10-30 sec | 1-2 min (Docker) |
| Port Forwarding | Manual (kubectl port-forward) | Automatic | Manual (minikube service/tunnel) |
| LoadBalancer | Manual setup | Built-in | Requires tunnel |
| Ingress Controller | Manual install | Built-in | Addon (manual enable) |
| Resource Usage | Medium (2GB+) | Low (512MB+) | High (2GB+) |
| CI/CD Friendly | ✅ Excellent | ✅ Good | ⚠️ Moderate |

---

## Recording the Demonstration

### Option 1: Using asciinema (Recommended)

**Installation**:
```bash
# macOS
brew install asciinema

# Linux/macOS (pip)
pip install asciinema

# Verify installation
asciinema --version
```

**Recording**:
```bash
# Record the demo script
asciinema rec demo-kind.cast -c "./demo-kind.sh"

# Play the recording locally
asciinema play demo-kind.cast

# Upload to asciinema.org
asciinema upload demo-kind.cast
```

**After Upload**:
- You'll receive a URL like: `https://asciinema.org/a/xxxxx`
- Share this URL or embed it in documentation
- The recording is interactive and can be played back
- Viewers can copy/paste commands from the recording

**Creating GIF**:
```bash
# Install agg (asciinema gif generator)
brew install agg  # macOS

# Convert cast to GIF
agg demo-kind.cast demo-kind.gif

# With custom theme (optional)
agg --theme monokai demo-kind.cast demo-kind.gif

# With custom speed (optional)
agg --speed 2 demo-kind.cast demo-kind.gif
```

### Option 2: Using script2gif (Alternative)

**Installation**:
```bash
# Install script2gif
npm install -g script2gif

# Record terminal session
script2gif -c "./demo-kind.sh" demo-kind.gif
```

### Option 3: Manual Recording

**Using macOS Screen Recording**:
1. Open Terminal
2. Press `Cmd + Shift + 5` to start screen recording
3. Select terminal window
4. Run `./demo-kind.sh`
5. Stop recording when done

**Using Linux (simplescreenrecorder)**:
```bash
# Install simplescreenrecorder
sudo apt install simplescreenrecorder

# Record terminal session
# Select terminal window and start recording
```

### Option 4: Using ttyrec (Terminal Recorder)

**Installation**:
```bash
# macOS
brew install ttyrec

# Linux
sudo apt install ttyrec
```

**Recording**:
```bash
# Record terminal session
ttyrec demo-kind.rec

# Playback
ttyplay demo-kind.rec
```

---

## Cleanup

After the demonstration, clean up all resources:

### Step 1: Stop Port-Forward Processes

```bash
# Stop all kubectl port-forward processes
pkill -f "kubectl port-forward"

# Verify port-forwards are stopped
ps aux | grep "kubectl port-forward"
```

### Step 2: Delete Kind Cluster

```bash
# Delete the cluster
kind delete cluster --name demo-cluster

# Verify deletion
kind get clusters
```

**Expected Output**:
```
No kind clusters found.
```

### Step 3: Clean Up /etc/hosts (if modified)

```bash
# Remove hello.local entry from /etc/hosts
sudo sed -i '' '/hello.local/d' /etc/hosts  # macOS
# or
sudo sed -i '/hello.local/d' /etc/hosts    # Linux

# Verify removal
cat /etc/hosts | grep hello.local
```

### Step 4: Clean Up Docker Resources (Optional)

```bash
# List kind-related containers (should be empty after cluster deletion)
docker ps -a | grep kind

# Remove any orphaned kind images (optional)
docker images | grep kindest/node
```

### Complete Cleanup Script

```bash
#!/bin/bash
# Complete cleanup script for kind demo

echo "Cleaning up kind demo..."

# Stop port-forwards
echo "Stopping port-forward processes..."
pkill -f "kubectl port-forward" || true

# Delete cluster
echo "Deleting kind cluster..."
kind delete cluster --name demo-cluster || true

# Clean up /etc/hosts
echo "Cleaning up /etc/hosts..."
sudo sed -i '' '/hello.local/d' /etc/hosts 2>/dev/null || \
sudo sed -i '/hello.local/d' /etc/hosts 2>/dev/null || true

# Verify cleanup
echo "Verifying cleanup..."
kind get clusters

echo "Cleanup complete!"
```

---

## Troubleshooting

### Issue: Kind Create Cluster Fails

**Error**: `ERROR: failed to create cluster: docker: command not found`

**Solution**:
```bash
# Verify Docker is installed and running
docker --version
docker ps

# Start Docker if not running
# macOS: Open Docker Desktop
# Linux: sudo systemctl start docker
```

### Issue: Port-Forward Not Working

**Error**: `error: unable to forward port because pod is not running`

**Solution**:
```bash
# Check pod status
kubectl get pods

# Check service status
kubectl get svc hello-world-service

# Verify service endpoints
kubectl get endpoints hello-world-service

# Restart port-forward
kubectl port-forward svc/hello-world-service 8080:80
```

### Issue: Ingress Controller Not Ready

**Error**: `error: timed out waiting for the condition`

**Solution**:
```bash
# Check Ingress Controller pods
kubectl get pods -n ingress-nginx

# Check pod logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Increase timeout
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

### Issue: kubectl Not Configured

**Error**: `The connection to the server localhost:6443 was refused`

**Solution**:
```bash
# Verify kind cluster exists
kind get clusters

# Check kubectl context
kubectl config get-contexts

# Switch to kind context if needed
kubectl config use-context kind-demo-cluster
```

### Issue: Port Already in Use

**Error**: `error: unable to listen on any of the requested ports`

**Solution**:
```bash
# Check what's using the port
lsof -i :8080

# Kill the process or use different port
kubectl port-forward svc/hello-world-service 8082:80
```

### Issue: Ingress Not Accessible

**Error**: `curl: (7) Failed to connect to hello.local`

**Solution**:
```bash
# Verify Ingress Controller is installed
kubectl get pods -n ingress-nginx

# Check Ingress status
kubectl get ingress

# Verify /etc/hosts entry
cat /etc/hosts | grep hello.local

# Verify port-forward is running
ps aux | grep "kubectl port-forward" | grep ingress-nginx

# Test with Host header
curl -H "Host: hello.local" http://localhost:8081
```

---

## Additional Resources

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kind GitHub](https://github.com/kubernetes-sigs/kind)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Docker Documentation](https://docs.docker.com/)

---

## Demo Script Reference

The automated demo script (`demo-kind.sh`) executes all steps above automatically. It includes:
- Color-coded output for better visibility
- Error handling with `set -e`
- Progress indicators for each step
- Automatic port-forward cleanup on exit
- Summary at the end

To use the script:
```bash
chmod +x demo-kind.sh
./demo-kind.sh
```

The script handles cleanup automatically when it exits, but you should still run `kind delete cluster --name demo-cluster` to completely remove the cluster.
