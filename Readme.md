# Local Kubernetes Tools Comparison

This repository contains a comprehensive comparative analysis of local Kubernetes development tools as part of the DevOps course curriculum.

## 📋 Overview

This project provides an in-depth comparison of three popular tools for running Kubernetes clusters locally:
- **minikube** - Official Kubernetes tool for local development
- **kind** - Kubernetes IN Docker (CI/CD focused)
- **k3d** - Lightweight Kubernetes distribution wrapper

The analysis includes detailed comparisons, practical demonstrations, and recommendations for different use cases.

## 📚 Documentation

### Main Documentation

- **[Concept Document](./doc/Concept.md)** - Comprehensive comparative analysis including:
  - Tool descriptions and purposes
  - Detailed characteristics comparison
  - Advantages and disadvantages
  - Practical demonstrations
  - Recommendations and conclusions
  - Docker licensing considerations

## 🎬 Demonstrations

### Demo Scripts

Interactive demo scripts are available for each tool:

- **[k3d Demo Script](./demo/demo-k3d.sh)** - Automated k3d demonstration
- **[Minikube Demo Script](./demo/demo-minikube.sh)** - Automated minikube demonstration
- **[Kind Demo Script](./demo/demo-kind.sh)** - Automated kind demonstration
- **[Cleanup Script](./demo/cleanup-all-clusters.sh)** - Clean up all clusters from all tools

### Demo Guides

Detailed step-by-step guides for each tool:

- **[k3d Demo Guide](./demo/K3D_DEMO.md)** - Complete k3d demonstration guide
- **[Minikube Demo Guide](./demo/Minikube_Demo.md)** - Complete minikube demonstration guide
- **[Kind Demo Guide](./demo/Kind_Demo.md)** - Complete kind demonstration guide

Each guide includes:
- Prerequisites and installation instructions
- Detailed step-by-step walkthrough
- Troubleshooting sections
- Recording and sharing instructions
- Cleanup procedures

## 🚀 Quick Start

### Running a Demo Locally

1. **Choose a tool** based on your needs:
   - **k3d** - Fastest startup, best for quick demos
   - **minikube** - Official support, best for learning
   - **kind** - Best for CI/CD integration

2. **Run the demo script**:
   ```bash
   # For k3d
   cd demo
   chmod +x demo-k3d.sh
   ./demo-k3d.sh
   
   # For minikube
   chmod +x demo-minikube.sh
   ./demo-minikube.sh
   
   # For kind
   chmod +x demo-kind.sh
   ./demo-kind.sh
   ```

3. **Follow the guide** for detailed explanations:
   - Read the corresponding demo guide (e.g., `K3D_DEMO.md`)
   - Follow step-by-step instructions
   - Review troubleshooting if needed

### Prerequisites

Before running any demo, ensure you have:

- **Docker** or **Podman** installed and running
- **kubectl** installed
- The respective tool installed:
  - k3d: `brew install k3d` or see [k3d installation](https://k3d.io/)
  - minikube: `brew install minikube` or see [minikube installation](https://minikube.sigs.k8s.io/docs/start/)
  - kind: `brew install kind` or see [kind installation](https://kind.sigs.k8s.io/docs/user/quick-start/)

## 📊 Key Findings

### Recommended Tool: k3d

Based on the analysis, **k3d is recommended** for PoC and local development due to:

- ⚡ **Fastest startup** (10-30 seconds)
- 💾 **Lowest resource consumption** (512MB+ RAM)
- 🔌 **Built-in LoadBalancer and Ingress Controller**
- 🎯 **Simple port forwarding** (automatic configuration)
- 🚀 **Ideal for demonstrations and PoC**

### When to Use Other Tools

- **Minikube**: When you need official Kubernetes support, built-in monitoring tools, or multiple driver options
- **Kind**: When focusing on CI/CD integration, automated testing, or Docker-based workflows

## 🧹 Cleanup

### Automated Cleanup Script

Use the provided cleanup script to remove all clusters from all tools:

```bash
cd demo
chmod +x cleanup-all-clusters.sh
./cleanup-all-clusters.sh
```

This script will:
- ✅ Check for and delete all k3d clusters
- ✅ Check for and delete all minikube clusters
- ✅ Check for and delete all kind clusters
- ✅ Stop all port-forward processes
- ✅ Clean up /etc/hosts entries (hello.local)
- ✅ Provide verification summary

### Manual Cleanup

If you prefer to clean up manually:

```bash
# k3d
k3d cluster delete demo-cluster
# or delete all
k3d cluster delete --all

# minikube
pkill -f "minikube tunnel"
minikube stop
minikube delete
# or delete all profiles
minikube delete --all

# kind
pkill -f "kubectl port-forward"
kind delete cluster --name demo-cluster
# or delete all
kind get clusters | xargs -I {} kind delete cluster --name {}
```

## 📝 Recording Demos

To record and share your demonstrations:

1. **Install asciinema**:
   ```bash
   brew install asciinema  # macOS
   pip install asciinema   # Linux/macOS
   ```

2. **Record the demo**:
   ```bash
   asciinema rec demo.cast -c "./demo-k3d.sh"
   ```

3. **Upload and share**:
   ```bash
   asciinema upload demo.cast
   ```

4. **Create GIF** (optional):
   ```bash
   brew install agg
   agg demo.cast demo.gif
   ```

See individual demo guides for detailed recording instructions.

## 📖 Course Context

This project is part of the **DevOps course curriculum** and demonstrates:

- Understanding of local Kubernetes development tools
- Practical comparison and evaluation skills
- Hands-on experience with multiple Kubernetes distributions
- Documentation and demonstration capabilities

## 🔗 Additional Resources

- [k3d Documentation](https://k3d.io/)
- [k3s Documentation](https://k3s.io/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 📄 License

This project is part of educational coursework.

---

**Note**: This repository contains educational materials for DevOps courses. For questions or contributions, please refer to the course instructor.
