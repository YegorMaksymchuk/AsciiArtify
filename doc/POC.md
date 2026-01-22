# ArgoCD Proof of Concept (PoC) - Demo Instructions

This document provides step-by-step instructions for accessing and using the ArgoCD GitOps system deployed on k3d Kubernetes cluster.

## Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This PoC demonstrates the installation and basic usage of ArgoCD on a local k3d cluster.

## Prerequisites

Before proceeding, ensure you have the following installed:

- **k3d** - Kubernetes distribution for local development
- **kubectl** - Kubernetes command-line tool
- **Docker** or **Podman** - Container runtime
- **bash** (macOS/Linux) or **PowerShell** (Windows) - Shell environment

### Installation Commands

#### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install k3d
brew install k3d

# Install kubectl
brew install kubectl

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
# Or via Homebrew:
brew install --cask docker
```

#### Linux

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Docker
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Fedora/RHEL/CentOS
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (to run without sudo)
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

#### Windows

```powershell
# Install k3d using Chocolatey (recommended)
# First install Chocolatey if not already installed:
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install k3d
choco install k3d

# Install kubectl using Chocolatey
choco install kubernetes-cli

# Alternative: Install kubectl manually
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Or using winget:
winget install Kubernetes.kubectl

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
# Or using Chocolatey:
choco install docker-desktop

# Install Git Bash (for running bash scripts)
# Download from: https://git-scm.com/download/win
# Or using Chocolatey:
choco install git
```

**Note for Windows Users**: 
- Use **Git Bash** or **WSL2** (Windows Subsystem for Linux) to run bash scripts
- Alternatively, use **PowerShell** with equivalent commands (see Windows-specific sections below)
- Ensure Docker Desktop is running before executing k3d commands

## Manual Installation Steps

This section provides manual step-by-step instructions for installing ArgoCD on each platform. These steps can be performed manually for learning purposes or troubleshooting. **For faster setup, automated bash scripts are available** (see [Automated Scripts](#automated-scripts) section below).

### Step 1: Create k3d Cluster

#### macOS / Linux

```bash
# Create k3d cluster with port forwarding
k3d cluster create asciiartify-poc \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

#### Windows (PowerShell)

```powershell
# Create k3d cluster with port forwarding
k3d cluster create asciiartify-poc --port "8080:80@loadbalancer" --port "8443:443@loadbalancer" --wait

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

**What this does:**
- Creates a k3d cluster named `asciiartify-poc`
- Configures port forwarding for ArgoCD GUI (port 8080)
- Waits for cluster to be ready
- Verifies cluster connectivity

### Step 2: Install ArgoCD

#### macOS / Linux

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD from official manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD server deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Apply LoadBalancer service (if manifest exists)
kubectl apply -f manifests/argocd-service.yaml

# Verify installation
kubectl get pods -n argocd
kubectl get svc -n argocd
```

#### Windows (PowerShell)

```powershell
# Create namespace
kubectl create namespace argocd

# Install ArgoCD from official manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD server deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Apply LoadBalancer service (if manifest exists)
kubectl apply -f manifests/argocd-service.yaml

# Verify installation
kubectl get pods -n argocd
kubectl get svc -n argocd
```

**What this does:**
- Creates the `argocd` namespace
- Installs ArgoCD components and CRDs from official stable release
- Waits for all pods to be ready (may take 2-5 minutes)
- Configures LoadBalancer service for GUI access
- Verifies installation status

**Note**: Installation may take 2-5 minutes. Wait for all pods to be in `Running` state.

### Step 3: Set Up Port Forwarding

ArgoCD GUI needs to be accessible via port forwarding (unless using LoadBalancer with external IP).

#### macOS / Linux

```bash
# Set up port forwarding in background
kubectl port-forward svc/argocd-server -n argocd 8080:8080 &

# Or run in foreground (press Ctrl+C to stop)
kubectl port-forward svc/argocd-server -n argocd 8080:8080
```

#### Windows (PowerShell)

```powershell
# Set up port forwarding in background
Start-Job -ScriptBlock { kubectl port-forward svc/argocd-server -n argocd 8080:8080 }

# Or run in foreground (press Ctrl+C to stop)
kubectl port-forward svc/argocd-server -n argocd 8080:8080
```

**What this does:**
- Forwards local port 8080 to ArgoCD server service port 8080
- Makes ArgoCD GUI accessible at `http://localhost:8080` or `https://localhost:8080`

**Note**: Keep the port forwarding process running. If running in background, note the PID to stop it later.

### Step 4: Get ArgoCD Credentials

Retrieve the initial admin password:

#### macOS / Linux

```bash
# Wait for secret to be created (may take a few seconds)
sleep 10

# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Display username
echo "Username: admin"
echo "ArgoCD GUI URL: https://localhost:8080"
```

#### Windows (PowerShell)

```powershell
# Wait for secret to be created
Start-Sleep -Seconds 10

# Get password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "Username: admin"
Write-Host "Password: $password"
Write-Host "ArgoCD GUI URL: https://localhost:8080"
```

**What this displays:**
- Username: `admin`
- Initial admin password (base64 decoded)
- ArgoCD GUI access URL

**Important**: Save the password securely. The initial admin password is only shown once. You can retrieve it again using the same command if needed.

### Step 5: Access ArgoCD GUI

#### Option 1: Via HTTPS (Recommended)

ArgoCD uses HTTPS by default. Access via:

```
https://localhost:8080
```

**Note**: You'll see a browser security warning due to self-signed certificate. Click "Advanced" → "Proceed to localhost" (or equivalent) to continue.

#### Option 2: Via HTTP (if configured)

If HTTP is enabled, access via:

```
http://localhost:8080
```

**macOS / Linux / Windows:**
- Open your web browser
- Navigate to `https://localhost:8080` (or `http://localhost:8080` if HTTP is enabled)
- Accept the security certificate warning if prompted

### Step 6: Login to ArgoCD

1. Open your web browser and navigate to `https://localhost:8080`
2. Login with:
   - **Username**: `admin`
   - **Password**: (use the password from Step 4)
3. After successful login, you'll see the ArgoCD dashboard

## Automated Scripts

All the manual steps above are **automated in bash scripts** for faster and easier setup. The scripts perform the same operations but with error handling, progress indicators, and automatic port forwarding setup.

### Quick Start with Scripts

#### macOS / Linux

```bash
cd 04_Kubernetes/01_Task

# Make scripts executable
chmod +x scripts/*.sh

# Step 1: Create k3d cluster
./scripts/setup-k3d-cluster.sh

# Step 2: Install ArgoCD (includes automatic port forwarding)
./scripts/install-argocd.sh

# Step 3: Get credentials
./scripts/get-argocd-credentials.sh
```

#### Windows (Git Bash)

```bash
cd 04_Kubernetes/01_Task

# Make scripts executable
chmod +x scripts/*.sh

# Step 1: Create k3d cluster
./scripts/setup-k3d-cluster.sh

# Step 2: Install ArgoCD (includes automatic port forwarding)
./scripts/install-argocd.sh

# Step 3: Get credentials
./scripts/get-argocd-credentials.sh
```

#### Windows (PowerShell)

```powershell
cd 04_Kubernetes\01_Task

# Run scripts via Git Bash or WSL2
bash scripts/setup-k3d-cluster.sh
bash scripts/install-argocd.sh
bash scripts/get-argocd-credentials.sh
```

### What the Scripts Do

The automated scripts (`setup-k3d-cluster.sh`, `install-argocd.sh`, `setup-argocd-port-forward.sh`, `get-argocd-credentials.sh`) perform the following:

1. **setup-k3d-cluster.sh**:
   - Checks prerequisites (k3d, kubectl, Docker)
   - Creates k3d cluster with port forwarding
   - Verifies cluster connectivity
   - Handles existing clusters gracefully

2. **install-argocd.sh**:
   - Creates ArgoCD namespace
   - Installs ArgoCD from official manifests
   - Waits for all pods to be ready
   - Applies LoadBalancer service
   - **Automatically calls `setup-argocd-port-forward.sh`** to set up port forwarding
   - Shows installation status

3. **setup-argocd-port-forward.sh** (called automatically by install-argocd.sh):
   - Checks if ArgoCD namespace and service exist
   - Detects existing port forwarding processes
   - Sets up port forwarding on port 8080 (or 8081 if 8080 is busy)
   - Handles port conflicts intelligently
   - Can be run standalone to restart or reconfigure port forwarding
   - Displays port forwarding status and PID

4. **get-argocd-credentials.sh**:
   - Waits for ArgoCD secret to be created
   - Retrieves and decodes admin password
   - Displays credentials and access URL
   - Provides port forwarding instructions if needed

### Benefits of Using Scripts

- **Faster setup**: All steps automated in sequence
- **Error handling**: Checks prerequisites and handles errors
- **Progress indicators**: Shows what's happening at each step
- **Automatic port forwarding**: Sets up port forwarding automatically with intelligent port conflict handling
- **Port conflict resolution**: Automatically uses alternative port (8081) if primary port (8080) is busy
- **Standalone port forwarding**: Can restart port forwarding independently without reinstalling ArgoCD
- **Consistent**: Same process every time
- **PID tracking**: Displays port forwarding PID for easy cleanup

### When to Use Manual Steps

Use manual steps when:
- Learning how ArgoCD installation works
- Troubleshooting issues with scripts
- Customizing the installation process
- Understanding each component
- Running on platforms where scripts don't work

### When to Use Scripts

Use scripts when:
- Quick setup is needed
- Standard installation is sufficient
- Reproducible setup is required
- Time-saving is important

### Standalone Port Forwarding Script

The `setup-argocd-port-forward.sh` script can be used independently to set up or restart port forwarding without reinstalling ArgoCD:

```bash
# Set up or restart port forwarding
./scripts/setup-argocd-port-forward.sh
```

**Use cases:**
- Port forwarding was stopped and needs to be restarted
- Port forwarding needs to be reconfigured
- Checking port forwarding status
- Switching between ports (8080/8081)

**Features:**
- Automatically detects existing port forwarding processes
- Handles port conflicts by using alternative port (8081)
- Shows port forwarding PID for easy management
- Can be run multiple times safely (won't create duplicates)

## ArgoCD CLI Access (Optional)

You can also access ArgoCD via CLI:

#### macOS

```bash
# Install ArgoCD CLI
brew install argocd

# Login
argocd login localhost:8080 --username admin --password <your-password>

# Verify connection
argocd version
```

#### Linux

```bash
# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login
argocd login localhost:8080 --username admin --password <your-password>

# Verify connection
argocd version
```

#### Windows

**Using Chocolatey:**
```powershell
# Install ArgoCD CLI
choco install argocd

# Login
argocd login localhost:8080 --username admin --password <your-password>

# Verify connection
argocd version
```

**Manual Installation:**
```powershell
# Download ArgoCD CLI
# Visit: https://github.com/argoproj/argo-cd/releases/latest
# Download: argocd-windows-amd64.exe
# Rename to: argocd.exe
# Add to PATH or place in a directory in your PATH

# Or download directly:
Invoke-WebRequest -Uri "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-windows-amd64.exe" -OutFile "argocd.exe"
# Move argocd.exe to a directory in your PATH (e.g., C:\Windows\System32)

# Login
argocd login localhost:8080 --username admin --password <your-password>

# Verify connection
argocd version
```

## Basic ArgoCD Usage

### View Applications

After logging in, you'll see the ArgoCD dashboard. Initially, there are no applications configured.

### Create Your First Application

1. Click **"New App"** or **"+ CREATE APPLICATION"**
2. Fill in the application details:
   - **Application Name**: `my-app`
   - **Project Name**: `default`
   - **Sync Policy**: `Manual` (for PoC) or `Automatic`
   - **Repository URL**: Your Git repository URL
   - **Path**: Path to Kubernetes manifests in the repository
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: Target namespace (e.g., `default`)
3. Click **"CREATE"**

### Sync Application

- **Manual Sync**: Click on your application → Click **"SYNC"** → Select resources → Click **"SYNCHRONIZE"**
- **Automatic Sync**: Enable in application settings for automatic synchronization

## Verification

### Check ArgoCD Pods

**macOS / Linux:**
```bash
kubectl get pods -n argocd
```

**Windows (PowerShell):**
```powershell
kubectl get pods -n argocd
```

Expected output should show all pods in `Running` state:
- `argocd-application-controller-*`
- `argocd-applicationset-controller-*`
- `argocd-dex-server-*`
- `argocd-notifications-controller-*`
- `argocd-redis-*`
- `argocd-repo-server-*`
- `argocd-server-*`

### Check ArgoCD Services

**macOS / Linux:**
```bash
kubectl get svc -n argocd
```

**Windows (PowerShell):**
```powershell
kubectl get svc -n argocd
```

You should see:
- `argocd-server` (LoadBalancer or ClusterIP)
- `argocd-repo-server`
- `argocd-redis`
- `argocd-dex-server`

### Check ArgoCD Server Logs

**macOS / Linux:**
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

**Windows (PowerShell):**
```powershell
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

## Troubleshooting

### ArgoCD Pods Not Starting

If pods are stuck in `Pending` or `ContainerCreating`:

**macOS / Linux:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n argocd

# Check pod logs
kubectl logs <pod-name> -n argocd
```

**Windows (PowerShell):**
```powershell
# Check pod events
kubectl describe pod <pod-name> -n argocd

# Check pod logs
kubectl logs <pod-name> -n argocd
```

### Cannot Access ArgoCD GUI

1. **Check port forwarding**:

   **Using the automated script (recommended):**
   ```bash
   ./scripts/setup-argocd-port-forward.sh
   ```
   This script will automatically detect existing port forwarding, handle port conflicts, and set up forwarding on an available port (8080 or 8081).

   **Manual port forwarding:**
   
   **macOS / Linux:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:8080
   ```

   **Windows (PowerShell):**
   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:8080
   ```

2. **Check service type**:

   **macOS / Linux / Windows:**
   ```bash
   kubectl get svc argocd-server -n argocd
   ```

3. **Verify LoadBalancer** (for k3d):

   **macOS / Linux:**
   ```bash
   kubectl get svc argocd-server -n argocd -o yaml
   ```

   **Windows (PowerShell):**
   ```powershell
   kubectl get svc argocd-server -n argocd -o yaml
   ```

### Forgot Admin Password

If you need to reset the admin password:

**macOS / Linux:**
```bash
# Get current password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Or update password via CLI
argocd account update-password
```

**Windows (PowerShell):**
```powershell
# Get current password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host $password

# Or update password via CLI
argocd account update-password
```

### Cluster Connection Issues

**macOS / Linux:**
```bash
# Verify cluster connection
kubectl cluster-info

# Check nodes
kubectl get nodes

# Verify context
kubectl config current-context
```

**Windows (PowerShell):**
```powershell
# Verify cluster connection
kubectl cluster-info

# Check nodes
kubectl get nodes

# Verify context
kubectl config current-context
```

## Cleanup

### Manual Cleanup

#### macOS / Linux

```bash
# Stop port forwarding (if running)
lsof -ti:8080 | xargs kill 2>/dev/null || true

# Or use saved PID file
kill $(cat .argocd-port-forward.pid) 2>/dev/null || true

# Delete k3d cluster
k3d cluster delete asciiartify-poc

# Or delete all k3d clusters
k3d cluster delete --all
```

#### Windows (PowerShell)

```powershell
# Stop port forwarding (find and kill process)
# Use Task Manager or:
Get-Process | Where-Object {$_.ProcessName -like "*kubectl*"} | Stop-Process

# Delete k3d cluster
k3d cluster delete asciiartify-poc

# Or delete all k3d clusters
k3d cluster list
k3d cluster delete --all
```

### Automated Cleanup

Use the cleanup script for easier removal:

#### macOS / Linux / Windows (Git Bash)

```bash
./scripts/cleanup.sh
```

This script will:
- Delete the k3d cluster `asciiartify-poc`
- Remove all associated resources
- Clean up port forwarding processes

**Note**: The cleanup script handles all cleanup steps automatically, including stopping port forwarding and deleting the cluster.

## Next Steps

After successfully setting up ArgoCD:

1. **Connect Git Repository**: Add your Git repository in ArgoCD settings
2. **Create Applications**: Define applications using ArgoCD Application CRD
3. **Configure Sync Policies**: Set up automatic sync and self-healing
4. **Set Up RBAC**: Configure role-based access control for team members
5. **Explore Features**: Try out ArgoCD features like:
   - Application health monitoring
   - Sync waves and hooks
   - Multi-cluster deployments
   - Application sets

## References

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [ArgoCD Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [ArgoCD User Guide](https://argo-cd.readthedocs.io/en/stable/user-guide/)
- [k3d Documentation](https://k3d.io/)

## Support

For issues or questions:
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`
- Review troubleshooting section above
- Consult [ArgoCD FAQ](https://argo-cd.readthedocs.io/en/stable/faq/)

---

## Summary

This document provides **two approaches** for setting up ArgoCD:

### 1. Manual Installation Steps

The **Manual Installation Steps** section (above) provides detailed step-by-step instructions for each platform (macOS, Linux, Windows) that can be executed manually. This approach is useful for:

- **Learning**: Understanding how ArgoCD installation works
- **Understanding**: Learning about each component and its purpose
- **Troubleshooting**: Identifying and fixing issues step-by-step
- **Customization**: Modifying the installation process to fit specific needs
- **Platform-specific**: Following platform-specific commands (PowerShell for Windows, bash for macOS/Linux)

### 2. Automated Scripts

The **Automated Scripts** section provides bash scripts that automate all manual steps for faster setup. The scripts (`setup-k3d-cluster.sh`, `install-argocd.sh`, `setup-argocd-port-forward.sh`, `get-argocd-credentials.sh`) perform the same operations as the manual steps but with:

- **Automatic error handling**: Checks prerequisites and handles errors gracefully
- **Progress indicators**: Shows what's happening at each step with colored output
- **Automatic port forwarding**: Sets up port forwarding automatically via `setup-argocd-port-forward.sh`
- **Intelligent port conflict handling**: Automatically uses alternative port (8081) if primary port (8080) is busy
- **Standalone port forwarding script**: Can restart port forwarding independently without reinstalling ArgoCD
- **PID tracking**: Displays port forwarding PID for easy cleanup
- **Consistency**: Same process every time, reducing human error
- **Time-saving**: Faster setup compared to manual steps

### Recommendation

- **For first-time setup or learning**: Follow the **Manual Installation Steps** to understand the process
- **For quick setup or repeated installations**: Use the **Automated Scripts** for faster execution
- **For troubleshooting**: Use manual steps to identify issues, then switch to scripts once resolved

Both approaches result in the same ArgoCD installation. Choose the method that best fits your needs:

- **Developers learning ArgoCD**: Start with manual steps, then use scripts for subsequent setups
- **DevOps engineers**: Use scripts for quick setup, refer to manual steps for troubleshooting
- **Platform-specific needs**: Use manual steps for Windows PowerShell or custom configurations

---

**PoC Status**: ✅ Ready for MVP implementation

**Last Updated**: 2025-01-27
