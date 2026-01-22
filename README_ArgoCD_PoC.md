# ArgoCD PoC on k3d

This directory contains scripts and documentation for deploying ArgoCD on a local k3d Kubernetes cluster as a Proof of Concept (PoC).

## Quick Start

1. **Create k3d cluster**
   ```bash
   ./scripts/setup-k3d-cluster.sh
   ```

2. **Install ArgoCD**
   ```bash
   ./scripts/install-argocd.sh
   ```
   This script automatically sets up port forwarding after installation.

3. **Get credentials**
   ```bash
   ./scripts/get-argocd-credentials.sh
   ```

4. **Access ArgoCD GUI**
   - Open browser: https://localhost:8080 (or http://localhost:8080)
   - If port 8080 is busy, the script will use port 8081 automatically
   - Accept security certificate warning if prompted (self-signed certificate)
   - Login with credentials from step 3

**Note**: Port forwarding is set up automatically by `install-argocd.sh`. If you need to set up port forwarding manually or restart it, use:
```bash
./scripts/setup-argocd-port-forward.sh
```

## Directory Structure

```
├── README_ArgoCD_PoC.md          # This file - Quick start guide
├── Readme_select_local_k8s_tool.md # Local K8s tool selection documentation
├── scripts/
│   ├── setup-k3d-cluster.sh      # Create k3d cluster with port forwarding
│   ├── install-argocd.sh         # Install ArgoCD (automatically calls port forwarding script)
│   ├── setup-argocd-port-forward.sh # Set up port forwarding for ArgoCD UI
│   ├── get-argocd-credentials.sh # Retrieve admin password
│   └── cleanup.sh                # Cleanup script to remove cluster
├── manifests/
│   └── argocd-service.yaml       # LoadBalancer service configuration
└── doc/
    └── POC.md                    # Detailed PoC documentation with manual steps
```

## Prerequisites

- k3d installed (`brew install k3d`)
- kubectl installed
- Docker running

## Documentation

For detailed instructions, including manual installation steps for all platforms (macOS, Windows, Linux) and automated script usage, see:

**[📖 Detailed PoC Documentation](doc/POC.md)**

The documentation includes:
- Manual installation steps for macOS, Linux, and Windows
- Automated script usage and benefits
- Troubleshooting guide
- ArgoCD CLI setup
- Platform-specific commands (PowerShell, bash)
- Cleanup procedures

## Cleanup

To remove the cluster and all resources:

```bash
./scripts/cleanup.sh
```
