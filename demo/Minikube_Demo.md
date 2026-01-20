# Minikube Demonstration Guide

This document provides a detailed demonstration plan for showcasing minikube capabilities, including cluster creation, application deployment, and port forwarding.

## Overview

This demonstration showcases minikube's key features:
- **Official Kubernetes support** from Kubernetes community
- **Multiple driver options** (Docker, VirtualBox, KVM, Hyper-V)
- **Built-in addons** for monitoring and visualization
- **LoadBalancer support** via minikube tunnel
- **Ingress Controller** via addon

## Prerequisites

Before running the demonstration, ensure you have the following installed:

- **Docker** or **Podman** (with podman-docker compatibility layer) - for Docker driver
- **kubectl** - Kubernetes command-line tool
- **minikube** - Install via one of the following methods:
  ```bash
  # macOS (Homebrew)
  brew install minikube
  
  # Linux
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  
  # Windows (via Chocolatey)
  choco install minikube
  
  # Verify installation
  minikube version
  ```

## Detailed Demo Plan

### Step 1: Start Minikube Cluster

**Objective**: Demonstrate cluster startup with Docker driver (fastest option).

**Command**:
```bash
minikube start --driver=docker
```

**What happens**:
- Starts a minikube cluster using Docker driver
- Creates a single-node Kubernetes cluster
- Configures kubectl context automatically
- Cluster startup typically takes 1-2 minutes with Docker driver (longer with VM drivers)

**Expected Output**:
```
😄  minikube v1.32.0 on Darwin 23.0.0
✨  Using the docker driver based on user configuration
📦  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔌  Configuring network plugins ...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

**Key Points to Highlight**:
- ✅ Cluster startup takes 1-2 minutes (faster with Docker driver)
- ✅ Automatically configures kubectl context
- ✅ Supports multiple drivers (Docker, VirtualBox, KVM, Hyper-V)

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
Kubernetes control plane is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.3
```

**Key Points to Highlight**:
- ✅ Cluster is ready and node is in `Ready` state
- ✅ Uses standard Kubernetes (100% compatibility)
- ✅ Single command to verify status

---

### Step 3: Enable Ingress Addon

**Objective**: Enable Ingress Controller addon (required for Ingress resources).

**Command**:
```bash
minikube addons enable ingress
```

**What happens**:
- Installs and enables the Ingress Controller addon
- Configures NGINX Ingress Controller
- Makes Ingress resources functional

**Expected Output**:
```
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.9.4
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20231011-8b53cabe0
    ▪ Verifying ingress addon...
🌟  The 'ingress' addon is enabled
```

**Key Points to Highlight**:
- ✅ Ingress addon must be enabled manually (not included by default)
- ✅ Uses NGINX Ingress Controller
- ✅ Takes a few moments to become ready

---

### Step 4: Deploy Hello World Application

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

### Step 5: Expose Service as LoadBalancer

**Objective**: Demonstrate LoadBalancer service type (requires minikube tunnel).

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
- LoadBalancer will get external IP when minikube tunnel is running

**Expected Output**:
```
service/hello-world-service exposed
```

**Key Points to Highlight**:
- ✅ LoadBalancer type requires `minikube tunnel` to work
- ✅ Without tunnel, external IP will remain `<pending>`
- ✅ Standard Kubernetes service configuration

---

### Step 6: Verify Deployment Status

**Objective**: Confirm pods and services are running correctly.

**Commands**:
```bash
sleep 5  # Allow time for service to be fully ready
kubectl get pods
kubectl get svc
```

**What happens**:
- `kubectl get pods` shows pod status and readiness
- `kubectl get svc` displays service configuration

**Expected Output**:
```
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-7d4b8c9f6b-xxxxx   1/1     Running   0          30s

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
hello-world-service    LoadBalancer   10.96.x.x       <pending>     80:xxxxx/TCP   10s
kubernetes             ClusterIP      10.96.0.1       <none>        443/TCP        2m
```

**Key Points to Highlight**:
- ✅ Pod is running and ready (1/1)
- ✅ Service has LoadBalancer type
- ✅ External IP shows `<pending>` until tunnel is started

---

### Step 7: Access via Minikube Service (Method 1)

**Objective**: Demonstrate the `minikube service` command for easy access.

**Command**:
```bash
minikube service hello-world-service --url
```

**What happens**:
- Returns the URL to access the service
- Can be used with `--url` flag to get URL only, or without flag to open in browser

**Expected Output**:
```
http://127.0.0.1:xxxxx
```

**Testing**:
```bash
SERVICE_URL=$(minikube service hello-world-service --url)
curl -s "$SERVICE_URL" | head -n 5
```

**Key Points to Highlight**:
- ✅ Simple way to access services without port-forwarding
- ✅ Works immediately without additional setup
- ✅ Can open in browser automatically (without `--url` flag)

---

### Step 8: Start Minikube Tunnel for LoadBalancer (Method 2)

**Objective**: Demonstrate LoadBalancer functionality with minikube tunnel.

**Command**:
```bash
minikube tunnel
```

**What happens**:
- Starts a network route that provides LoadBalancer IPs to services
- Runs in foreground (use `&` to run in background)
- Routes traffic from LoadBalancer external IPs to services
- Service will get an external IP assigned (typically 127.0.0.1 or 10.x.x.x)

**Running in Background**:
```bash
minikube tunnel &
TUNNEL_PID=$!
sleep 10  # Wait for tunnel to establish
```

**Check LoadBalancer IP**:
```bash
kubectl get svc hello-world-service
```

**Expected Output** (after tunnel starts):
```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
hello-world-service    LoadBalancer   10.96.x.x       127.0.0.1     80:xxxxx/TCP   30s
```

**Testing**:
```bash
curl -s http://127.0.0.1 | head -n 5
```

**Key Points to Highlight**:
- ✅ LoadBalancer gets external IP when tunnel is running
- ✅ Tunnel must run continuously (background process)
- ✅ More complex than k3d's automatic port forwarding
- ✅ Requires manual tunnel management

---

### Step 9: Create Ingress Resource

**Objective**: Demonstrate minikube's Ingress Controller addon.

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
- NGINX Ingress Controller (from addon) picks up the Ingress
- Routes traffic from `hello.local` to the `hello-world-service`

**Expected Output**:
```
ingress.networking.k8s.io/hello-world-ingress created
```

**Access via Ingress**:
```bash
# Get minikube IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts (macOS/Linux)
echo "$MINIKUBE_IP hello.local" | sudo tee -a /etc/hosts

# Test Ingress
curl http://hello.local
```

**Key Points to Highlight**:
- ✅ Ingress Controller available via addon (must be enabled)
- ✅ Requires /etc/hosts entry with minikube IP
- ✅ Works after Ingress Controller is ready
- ✅ Supports host-based and path-based routing

---

## Demo Summary

### What Was Demonstrated

1. **Cluster Startup**: Cluster started in 1-2 minutes (Docker driver)
2. **Addon Management**: Ingress addon enabled manually
3. **LoadBalancer Access**: Two methods - `minikube service` and `minikube tunnel`
4. **Standard Kubernetes Workflow**: All standard kubectl commands work
5. **Ingress Support**: Via addon (requires manual enablement)
6. **Multiple Access Methods**: Service URL, LoadBalancer IP, and Ingress

### Access Points

After completing the demo, the application is accessible via:

- **Minikube Service**: `minikube service hello-world-service --url`
- **LoadBalancer**: `http://127.0.0.1` (when tunnel is running)
- **Ingress**: `http://hello.local` (requires /etc/hosts entry with minikube IP)

### Key Characteristics Demonstrated

| Feature | Minikube | k3d | Kind |
|---------|----------|-----|------|
| Cluster Creation Time | 1-2 min (Docker) | 10-30 sec | 30-60 sec |
| Port Forwarding | Manual (minikube service/tunnel) | Automatic | Manual (kubectl port-forward) |
| LoadBalancer | Requires tunnel | Built-in | Manual setup |
| Ingress Controller | Addon (manual enable) | Built-in | Manual install |
| Resource Usage | High (2GB+) | Low (512MB+) | Medium (2GB+) |

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
asciinema rec demo-minikube.cast -c "./demo-minikube.sh"

# Play the recording locally
asciinema play demo-minikube.cast

# Upload to asciinema.org
asciinema upload demo-minikube.cast
```

**After Upload**:
- You'll receive a URL like: `https://asciinema.org/a/xxxxx`
- Share this URL or embed it in documentation
- The recording is interactive and can be played back

**Creating GIF**:
```bash
# Install agg (asciinema gif generator)
brew install agg  # macOS

# Convert cast to GIF
agg demo-minikube.cast demo-minikube.gif

# With custom theme (optional)
agg --theme monokai demo-minikube.cast demo-minikube.gif
```

### Option 2: Using script2gif (Alternative)

**Installation**:
```bash
# Install script2gif
npm install -g script2gif

# Record terminal session
script2gif -c "./demo-minikube.sh" demo-minikube.gif
```

### Option 3: Manual Recording

**Using macOS Screen Recording**:
1. Open Terminal
2. Press `Cmd + Shift + 5` to start screen recording
3. Select terminal window
4. Run `./demo-minikube.sh`
5. Stop recording when done

**Using Linux (simplescreenrecorder)**:
```bash
# Install simplescreenrecorder
sudo apt install simplescreenrecorder

# Record terminal session
# Select terminal window and start recording
```

---

## Cleanup

After the demonstration, clean up all resources:

### Step 1: Stop Minikube Tunnel

```bash
# If tunnel is running in foreground, press Ctrl+C
# If running in background, kill the process
pkill -f "minikube tunnel"

# Verify tunnel is stopped
ps aux | grep "minikube tunnel"
```

### Step 2: Stop Minikube Cluster

```bash
# Stop the cluster (keeps VM/container but stops Kubernetes)
minikube stop
```

**Expected Output**:
```
✋  Stopping node "minikube" ...
🛑  1 node stopped.
```

### Step 3: Delete Minikube Cluster

```bash
# Delete the cluster completely
minikube delete

# Verify deletion
minikube status
```

**Expected Output**:
```
minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Stopped
```

Or if completely deleted:
```
❌  Exiting due to GUEST_MISSING: VM does not exist
```

### Step 4: Clean Up /etc/hosts (if modified)

```bash
# Remove hello.local entry from /etc/hosts
sudo sed -i '' '/hello.local/d' /etc/hosts  # macOS
# or
sudo sed -i '/hello.local/d' /etc/hosts    # Linux
```

### Complete Cleanup Script

```bash
#!/bin/bash
# Complete cleanup script for minikube demo

echo "Cleaning up minikube demo..."

# Stop tunnel
echo "Stopping minikube tunnel..."
pkill -f "minikube tunnel" || true

# Stop cluster
echo "Stopping minikube cluster..."
minikube stop || true

# Delete cluster
echo "Deleting minikube cluster..."
minikube delete || true

# Clean up /etc/hosts
echo "Cleaning up /etc/hosts..."
sudo sed -i '' '/hello.local/d' /etc/hosts 2>/dev/null || \
sudo sed -i '/hello.local/d' /etc/hosts 2>/dev/null || true

echo "Cleanup complete!"
```

---

## Troubleshooting

### Issue: Minikube Start Fails

**Error**: `Error: [VBOX_NOT_FOUND] VBoxManage not found`

**Solution**:
```bash
# Use Docker driver instead
minikube start --driver=docker

# Or install VirtualBox
brew install virtualbox  # macOS
```

### Issue: Tunnel Not Working

**Error**: LoadBalancer external IP remains `<pending>`

**Solution**:
```bash
# Check if tunnel is running
ps aux | grep "minikube tunnel"

# Start tunnel if not running
minikube tunnel

# Check service status
kubectl get svc hello-world-service
```

### Issue: kubectl Not Configured

**Error**: `The connection to the server localhost:6443 was refused`

**Solution**:
```bash
# Verify minikube is running
minikube status

# Check kubectl context
kubectl config get-contexts

# Switch to minikube context if needed
kubectl config use-context minikube
```

### Issue: Ingress Not Accessible

**Error**: `curl: (7) Failed to connect to hello.local`

**Solution**:
```bash
# Verify Ingress addon is enabled
minikube addons list | grep ingress

# Enable if not enabled
minikube addons enable ingress

# Check Ingress status
kubectl get ingress

# Verify /etc/hosts entry
cat /etc/hosts | grep hello.local

# Get minikube IP and add to /etc/hosts
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP hello.local" | sudo tee -a /etc/hosts
```

### Issue: Port Already in Use

**Error**: `Error: port 8080 is already in use`

**Solution**:
```bash
# Check what's using the port
lsof -i :8080

# Kill the process or use different port
# For minikube service, ports are assigned automatically
```

---

## Additional Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Minikube GitHub](https://github.com/kubernetes/minikube)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

## Demo Script Reference

The automated demo script (`demo-minikube.sh`) executes all steps above automatically. It includes:
- Color-coded output for better visibility
- Error handling with `set -e`
- Progress indicators for each step
- Automatic tunnel cleanup on exit
- Summary at the end

To use the script:
```bash
chmod +x demo-minikube.sh
./demo-minikube.sh
```

The script handles cleanup automatically when it exits, but you should still run `minikube delete` to completely remove the cluster.
