# Kubernetes Task 1 - Local Kubernetes Tools & ArgoCD PoC

This directory contains comprehensive documentation, scripts, and demonstrations for local Kubernetes development tools comparison and ArgoCD Proof of Concept (PoC) implementation.

## 📋 Overview

This task covers two main components:

1. **Local Kubernetes Tools Comparison**: Comparative analysis and demonstrations of minikube, kind, and k3d
2. **ArgoCD PoC**: Complete setup and deployment of ArgoCD GitOps system on k3d cluster

## 📁 Directory Structure

```
04_Kubernetes/01_Task/
├── README.md                        # This file - Main directory overview
├── README_ArgoCD_PoC.md            # Quick start guide for ArgoCD PoC
├── Readme_select_local_k8s_tool.md  # Local K8s tool selection documentation
├── scripts/                         # ArgoCD PoC automation scripts
│   ├── setup-k3d-cluster.sh        # Create k3d cluster with port forwarding
│   ├── install-argocd.sh           # Install ArgoCD (automatically sets up port forwarding)
│   ├── setup-argocd-port-forward.sh # Set up port forwarding for ArgoCD UI
│   ├── get-argocd-credentials.sh   # Retrieve admin password
│   └── cleanup.sh                  # Cleanup script to remove cluster
├── manifests/                      # Kubernetes manifests
│   └── argocd-service.yaml         # LoadBalancer service configuration
├── doc/                            # Detailed documentation
│   ├── Concept.md                  # Comprehensive K8s tools comparison
│   └── POC.md                      # Detailed ArgoCD PoC documentation
└── demo/                           # Demo scripts and recordings
    ├── demo-k3d.sh                 # k3d demonstration script
    ├── demo-k3d.cast               # k3d asciinema recording
    ├── demo-kind.sh                # kind demonstration script
    ├── demo-kind.cast              # kind asciinema recording
    ├── demo-minikube.sh            # minikube demonstration script
    ├── demo-minikube.cast          # minikube asciinema recording
    ├── cleanup-all-clusters.sh     # Cleanup script for all clusters
    ├── K3D_DEMO.md                 # k3d demo documentation
    ├── Kind_Demo.md                # kind demo documentation
    └── Minikube_Demo.md            # minikube demo documentation
```

## 🎯 Components

### 1. Local Kubernetes Tools Comparison

**Purpose**: Compare and evaluate minikube, kind, and k3d for local Kubernetes development.

**Key Files**:
- `Readme_select_local_k8s_tool.md` - Overview and quick reference
- `doc/Concept.md` - Comprehensive comparative analysis
- `demo/` - Interactive demonstrations for each tool

**Features**:
- Detailed comparison table (resource requirements, startup speed, features)
- Practical demonstrations with Hello World applications
- Platform-specific installation instructions
- Recommendations based on use cases

**Quick Start**:
```bash
# Run k3d demo
cd demo
./demo-k3d.sh

# Run kind demo
./demo-kind.sh

# Run minikube demo
./demo-minikube.sh
```

### 2. ArgoCD Proof of Concept (PoC)

**Purpose**: Deploy and configure ArgoCD GitOps system on a local k3d Kubernetes cluster.

**Key Files**:
- `README_ArgoCD_PoC.md` - Quick start guide
- `doc/POC.md` - Comprehensive documentation with manual steps
- `scripts/` - Automation scripts for setup and cleanup
- `manifests/` - Kubernetes manifests

**Features**:
- Automated installation scripts
- Manual installation steps for all platforms (macOS, Windows, Linux)
- Automatic port forwarding setup (with fallback to alternative port)
- Standalone port forwarding script for manual control
- Credential management
- Troubleshooting guide

**Quick Start**:
```bash
# Automated setup
./scripts/setup-k3d-cluster.sh
./scripts/install-argocd.sh
./scripts/get-argocd-credentials.sh

# Access ArgoCD GUI
# Open browser: https://localhost:8080
```

## 📚 Documentation

### Main Documentation Files

1. **[README_ArgoCD_PoC.md](README_ArgoCD_PoC.md)**
   - Quick start guide for ArgoCD PoC
   - Script usage instructions
   - Prerequisites and cleanup

2. **[Readme_select_local_k8s_tool.md](Readme_select_local_k8s_tool.md)**
   - Overview of local K8s tools comparison
   - Demo scripts and recordings
   - Tool selection guidance

3. **[doc/Concept.md](doc/Concept.md)**
   - Comprehensive comparative analysis
   - Detailed tool characteristics
   - Advantages and disadvantages
   - Recommendations and conclusions

4. **[doc/POC.md](doc/POC.md)**
   - Detailed ArgoCD PoC documentation
   - Manual installation steps for all platforms
   - Automated script usage
   - Troubleshooting guide
   - Platform-specific commands (PowerShell, bash)

## 🚀 Quick Start Guides

### For Local K8s Tools Comparison

1. Read the [Concept Document](doc/Concept.md) for detailed comparison
2. Run demo scripts in the `demo/` directory
3. Review demo documentation (K3D_DEMO.md, Kind_Demo.md, Minikube_Demo.md)

### For ArgoCD PoC

1. Follow the [ArgoCD PoC Quick Start](README_ArgoCD_PoC.md)
2. Or use detailed [POC Documentation](doc/POC.md) for manual steps
3. Access ArgoCD GUI at `https://localhost:8080`

## 🛠️ Prerequisites

### For Local K8s Tools Comparison

- Docker or Podman installed and running
- kubectl installed
- One or more of: minikube, kind, or k3d

### For ArgoCD PoC

- k3d installed (`brew install k3d` on macOS)
- kubectl installed
- Docker running
- bash shell (or Git Bash/PowerShell on Windows)

## 📖 Usage Examples

### Compare Local K8s Tools

```bash
# Read the concept document
cat doc/Concept.md

# Run k3d demo
cd demo
./demo-k3d.sh

# Compare with other tools
./demo-kind.sh
./demo-minikube.sh
```

### Deploy ArgoCD PoC

```bash
# Automated setup
./scripts/setup-k3d-cluster.sh
./scripts/install-argocd.sh
./scripts/get-argocd-credentials.sh

# Or follow manual steps in doc/POC.md
```

## 🧹 Cleanup

### Cleanup All Demo Clusters

```bash
cd demo
./cleanup-all-clusters.sh
```

### Cleanup ArgoCD PoC

```bash
./scripts/cleanup.sh
```

## 🎓 Learning Path

1. **Start Here**: Read `Readme_select_local_k8s_tool.md` for overview
2. **Deep Dive**: Study `doc/Concept.md` for detailed comparison
3. **Hands-On**: Run demo scripts in `demo/` directory
4. **ArgoCD Setup**: Follow `README_ArgoCD_PoC.md` for quick start
5. **Advanced**: Read `doc/POC.md` for manual steps and troubleshooting

## 🔗 Related Documentation

- [k3d Documentation](https://k3d.io/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [minikube Documentation](https://minikube.sigs.k8s.io/)
- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)

## 📝 Notes

- **Tool Selection**: k3d is recommended for PoC due to fast startup and built-in LoadBalancer
- **Platform Support**: All scripts support macOS, Linux, and Windows (via Git Bash/WSL2)
- **Manual vs Automated**: Both manual steps and automated scripts are provided
- **Port Forwarding**: ArgoCD scripts automatically set up port forwarding to localhost:8080

## 🤝 Contributing

When adding new content:
- Update this README.md with new files/directories
- Add appropriate documentation in `doc/` directory
- Include platform-specific instructions (macOS, Linux, Windows)
- Provide both manual steps and automated scripts when possible

---

**Status**: ✅ Complete

**Last Updated**: 2025-01-27
