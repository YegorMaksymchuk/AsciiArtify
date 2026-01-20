# k3d Demonstration Guide

This document provides a detailed demonstration plan for showcasing k3d capabilities, including cluster creation, application deployment, and port forwarding.

## Overview

This demonstration showcases k3d's key advantages:
- **Fast cluster creation** (10-30 seconds)
- **Simple port forwarding** through Docker port mapping
- **Built-in LoadBalancer** (Traefik)
- **Built-in Ingress Controller** (Traefik)
- **Easy application deployment** and access

## Prerequisites

Before running the demonstration, ensure you have the following installed:

- **Docker** or **Podman** (with podman-docker compatibility layer)
- **kubectl** - Kubernetes command-line tool
- **k3d** - Install via one of the following methods:
  ```bash
  # macOS (Homebrew)
  brew install k3d
  
  # Linux/macOS (Install script)
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  
  # Verify installation
  k3d --version
  ```

## Detailed Demo Plan

### Step 1: Create k3d Cluster with Port Forwarding

**Objective**: Demonstrate fast cluster creation with automatic port forwarding configuration.

**Command**:
```bash
k3d cluster create demo-cluster \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait
```

**What happens**:
- Creates a new k3d cluster named `demo-cluster`
- Configures port forwarding:
  - Host port `8080` → LoadBalancer port `80` (HTTP)
  - Host port `8443` → LoadBalancer port `443` (HTTPS)
- `--wait` flag ensures cluster is fully ready before proceeding
- Cluster creation typically takes 10-30 seconds

**Expected Output**:
```
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-demo-cluster'
INFO[0000] Created image volume k3d-demo-cluster-images
INFO[0001] Starting new tools node...
INFO[0001] Starting cluster 'demo-cluster'
INFO[0002] Creating initializing server node...
INFO[0003] Creating loadbalancer...
INFO[0004] Starting the loadbalancer...
INFO[0005] Injecting records for hostAliases (incl. host.k3d.internal) and for 2 network members into CoreDNS configmap...
INFO[0006] Cluster 'demo-cluster' created successfully!
```

**Key Points to Highlight**:
- ✅ Cluster created in seconds (not minutes)
- ✅ Port forwarding configured automatically
- ✅ LoadBalancer included by default (no addon installation needed)

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
Kubernetes control plane is running at https://0.0.0.0:6443
CoreDNS is running at https://0.0.0.0:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME                    STATUS   ROLES           AGE   VERSION
k3d-demo-cluster-0     Ready    control-plane   30s   v1.28.2+k3s2
```

**Key Points to Highlight**:
- ✅ Cluster is ready and nodes are in `Ready` state
- ✅ Uses k3s (lightweight Kubernetes) but fully CNCF-certified
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

### Step 4: Expose Service as LoadBalancer

**Objective**: Demonstrate k3d's built-in LoadBalancer functionality.

**Command**:
```bash
kubectl expose deployment hello-world \
  --type=LoadBalancer \
  --port=80 \
  --target-port=80 \
  --name=hello-world-service
```

**What happens**:
- Creates a Service of type `LoadBalancer`
- Exposes port 80 on the service
- Maps to port 80 on the pods (target-port)
- k3d's built-in Traefik LoadBalancer automatically handles the service

**Expected Output**:
```
service/hello-world-service exposed
```

**Key Points to Highlight**:
- ✅ LoadBalancer type works immediately (no addon installation)
- ✅ No need for `minikube tunnel` or additional configuration
- ✅ Service is automatically accessible via port forwarding

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
- `kubectl get svc` displays service configuration and external IP

**Expected Output**:
```
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-7d4b8c9f6b-xxxxx   1/1     Running   0          30s

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
hello-world-service    LoadBalancer   10.43.x.x       0.0.0.0       80:xxxxx/TCP   10s
kubernetes             ClusterIP      10.43.0.1       <none>        443/TCP        1m
```

**Key Points to Highlight**:
- ✅ Pod is running and ready (1/1)
- ✅ Service has LoadBalancer type
- ✅ External IP shows `0.0.0.0` (accessible via port forwarding)

---

### Step 6: Test Application Access

**Objective**: Demonstrate automatic port forwarding and application accessibility.

**Command**:
```bash
curl -s http://localhost:8080 | head -n 5
```

**What happens**:
- Accesses the application via `localhost:8080`
- Port forwarding configured in Step 1 automatically routes traffic
- LoadBalancer forwards to the service, which routes to the pod

**Expected Output**:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

**Key Points to Highlight**:
- ✅ **No manual port forwarding needed** (unlike minikube)
- ✅ Application accessible immediately after service creation
- ✅ Works exactly like production LoadBalancer behavior
- ✅ Can also open `http://localhost:8080` in a browser

**Alternative Access Methods**:
```bash
# Using browser (macOS)
open http://localhost:8080

# Using browser (Linux)
xdg-open http://localhost:8080

# Full HTML response
curl http://localhost:8080
```

---

### Step 7: Create Ingress Resource

**Objective**: Demonstrate k3d's built-in Ingress Controller (Traefik).

**Command**:
```bash
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
```

**What happens**:
- Creates an Ingress resource for host-based routing
- Traefik (built-in Ingress Controller) automatically picks up the Ingress
- Routes traffic from `hello.local` to the `hello-world-service`

**Expected Output**:
```
ingress.networking.k8s.io/hello-world-ingress created
```

**Access via Ingress**:
```bash
# Add to /etc/hosts (macOS/Linux)
echo "127.0.0.1 hello.local" | sudo tee -a /etc/hosts

# Test Ingress
curl http://hello.local
```

**Key Points to Highlight**:
- ✅ Ingress Controller already installed (Traefik)
- ✅ No need to install or configure Ingress Controller separately
- ✅ Works immediately after applying Ingress resource
- ✅ Supports host-based and path-based routing

---

## Demo Summary

### What Was Demonstrated

1. **Fast Cluster Creation**: Cluster created in 10-30 seconds
2. **Automatic Port Forwarding**: Configured during cluster creation
3. **Built-in LoadBalancer**: Works immediately without addons
4. **Standard Kubernetes Workflow**: All standard kubectl commands work
5. **Built-in Ingress**: Traefik included and ready to use
6. **Easy Application Access**: Applications accessible via localhost immediately

### Access Points

After completing the demo, the application is accessible via:

- **LoadBalancer**: `http://localhost:8080`
- **Ingress**: `http://hello.local` (requires /etc/hosts entry)

### Key Advantages Demonstrated

| Feature | k3d | Minikube | Kind |
|---------|-----|----------|------|
| Cluster Creation Time | 10-30 sec | 1-5 min | 30-60 sec |
| Port Forwarding | Automatic | Manual (minikube service) | Manual (kubectl port-forward) |
| LoadBalancer | Built-in | Requires addon | Manual setup |
| Ingress Controller | Built-in | Requires addon | Manual setup |
| Resource Usage | Low (512MB+) | High (2GB+) | Medium (2GB+) |

---

## Recording the Demonstration

### Option 1: Using asciinema (Recommended)

**Installation**:
```bash
# macOS
brew install asciinema

# Linux/macOS (pip)
pip install asciinema
```

**Recording**:
```bash
# Record the demo script
asciinema rec demo-k3d.cast -c "./demo-k3d.sh"

# Play the recording
asciinema play demo-k3d.cast

# Upload to asciinema.org (optional)
asciinema upload demo-k3d.cast
```

**Creating GIF**:
```bash
# Install agg (asciinema gif generator)
brew install agg  # macOS

# Convert cast to GIF
agg demo-k3d.cast demo-k3d.gif
```

### Option 2: Direct Script Execution

```bash
# Make script executable
chmod +x demo-k3d.sh

# Run the demo
./demo-k3d.sh
```

### Option 3: Manual Step-by-Step

Follow the detailed steps outlined in this document, executing each command manually to explain the process in detail.

---

## Cleanup

After the demonstration, clean up the cluster:

```bash
# Delete the demo cluster
k3d cluster delete demo-cluster

# Verify deletion
k3d cluster list
```

**Expected Output**:
```
NAME   SERVERS   AGENTS   LOADBALANCER
```

(No clusters listed)

---

## Troubleshooting

### Issue: Port Already in Use

**Error**: `Error: failed to create cluster: failed to create loadbalancer: failed to start loadbalancer container`

**Solution**:
```bash
# Check if port is in use
lsof -i :8080

# Use different port
k3d cluster create demo-cluster \
  --port "8081:80@loadbalancer" \
  --wait
```

### Issue: kubectl Not Configured

**Error**: `The connection to the server localhost:6443 was refused`

**Solution**:
```bash
# k3d automatically configures kubectl, but verify:
kubectl config get-contexts

# Switch to k3d context if needed
kubectl config use-context k3d-demo-cluster
```

### Issue: Pod Not Starting

**Error**: Pod status shows `ImagePullBackOff` or `ErrImagePull`

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Verify Docker/Podman is running
docker ps
# or
podman ps
```

### Issue: Service Not Accessible

**Error**: `curl: (7) Failed to connect to localhost port 8080`

**Solution**:
```bash
# Verify service is running
kubectl get svc hello-world-service

# Check if port forwarding is configured
k3d cluster list

# Verify LoadBalancer is running
docker ps | grep loadbalancer
```

---

## Additional Resources

- [k3d Documentation](https://k3d.io/)
- [k3s Documentation](https://k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

---

## Demo Script Reference

The automated demo script (`demo-k3d.sh`) executes all steps above automatically. It includes:
- Color-coded output for better visibility
- Error handling with `set -e`
- Progress indicators for each step
- Summary at the end

To use the script:
```bash
./demo-k3d.sh
```
