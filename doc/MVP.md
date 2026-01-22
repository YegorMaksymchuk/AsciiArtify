# MVP: ArgoCD GitOps Deployment

## Overview

This MVP (Minimum Viable Product) demonstrates a complete GitOps workflow using ArgoCD to deploy and manage the `go-demo-app` application on a Kubernetes cluster. The implementation showcases automated synchronization, self-healing capabilities, and the full GitOps cycle from Git repository to running application.

### Objectives

- Deploy ArgoCD Application that tracks Git repository
- Configure automated synchronization with self-healing
- Demonstrate GitOps workflow: Git → ArgoCD → Kubernetes
- Show application functionality and API endpoints
- Document the complete deployment process

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Git Repository                        │
│  https://github.com/YegorMaksymchuk/go-demo-app          │
│  Branch: feature/fix-for-argo-sycn                      │
│  Path: yaml/                                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Monitors
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    ArgoCD                                │
│  Namespace: argocd                                       │
│  Application: go-demo-app                                 │
│  Sync Policy: Automated (prune, selfHeal)                │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Deploys
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (k3d)                     │
│  Namespace: demo                                         │
│  Resources:                                              │
│    - Pods (app, app-two-containers, etc.)               │
│    - CronJob (app-cronjob)                              │
│    - Jobs                                               │
│    - ConfigMaps, Secrets, etc.                           │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

- **k3d** - Kubernetes distribution for local development
- **kubectl** - Kubernetes command-line tool
- **Docker** - Container runtime
- **bash** - Shell environment

### Cluster and ArgoCD Status

Before proceeding, ensure:

- k3d cluster is running: `kubectl cluster-info`
- ArgoCD is installed: `kubectl get pods -n argocd`
- ArgoCD UI is accessible: `http://localhost:8080`
- Application is created: `kubectl get application go-demo-app -n argocd`

### Installation Commands

If prerequisites are not met, follow these steps:

```bash
# 1. Create k3d cluster
./scripts/setup-k3d-cluster.sh

# 2. Install ArgoCD
./scripts/install-argocd.sh

# 3. Get ArgoCD credentials
./scripts/get-argocd-credentials.sh
```

## Deployment Instructions

### Step 1: Create ArgoCD Application

The Application manifest is located at `manifests/go-demo-app-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: go-demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/YegorMaksymchuk/go-demo-app'
    path: yaml
    targetRevision: feature/fix-for-argo-sycn
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Key Configuration:**
- **Repository**: Forked repository with fixed CronJob API version (`batch/v1`)
- **Branch**: `feature/fix-for-argo-sycn` (contains fix for deprecated API)
- **Sync Policy**: Automated with prune and self-healing enabled
- **Namespace**: Resources deployed to `demo` namespace

### Step 2: Apply Application Manifest

```bash
kubectl apply -f manifests/go-demo-app-application.yaml
```

### Step 3: Verify Application Status

```bash
# Check Application sync status
kubectl get application go-demo-app -n argocd

# Check detailed status
kubectl describe application go-demo-app -n argocd

# Verify deployed resources
kubectl get all -n demo
```

**Expected Output:**
- Sync Status: `Synced`
- Health Status: `Degraded` (some demo pods have image pull issues, but main app works)
- Resources: Multiple pods, CronJob, Jobs deployed

### Step 4: Access ArgoCD UI

1. Open browser: `http://localhost:8080`
2. Login with credentials (obtained from `./scripts/get-argocd-credentials.sh`)
3. Navigate to Application `go-demo-app`
4. View sync status, resource tree, and application details

## Application Functionality

### Application Overview

The `go-demo-app` is a Go-based demo application that provides various API endpoints for testing and demonstration purposes.

### API Endpoints

#### 1. Root Endpoint

```bash
curl http://localhost:8082/
```

**Response:**
```
Version: 1.0.0
```

#### 2. API Endpoint

```bash
curl http://localhost:8082/api/
```

**Response:**
```
Version: 1.0.0
```

#### 3. ASCII Art Endpoint

```bash
curl -X POST --data '{"text":"Hello World"}' http://localhost:8082/ascii/
```

Converts text to ASCII art representation.

#### 4. Image Processing Endpoint

```bash
curl -F 'image=@/path/to/image.png' http://localhost:8082/img/
```

Processes uploaded images.

#### 5. ML5 Endpoint

```bash
curl http://localhost:8082/ml5/
```

Machine learning functionality endpoint.

### Accessing the Application

Since the application is deployed in a k3d cluster without LoadBalancer support, use port-forwarding:

```bash
# Set up port-forwarding (port 8082 to avoid conflict with ArgoCD on 8080)
kubectl port-forward pod/app -n demo 8082:8080

# In another terminal, test the API
curl http://localhost:8082/api/
```

**Note:** Port 8082 is used to avoid conflict with ArgoCD UI on port 8080.

### Application Status

```bash
# Check pod status
kubectl get pod app -n demo

# View logs
kubectl logs pod/app -n demo

# Check all resources
kubectl get all -n demo
```

**Current Status:**
- Main application pod (`app`): `Running`
- Application API: Accessible on `http://localhost:8082`
- Version: `1.0.0`

## Automated Synchronization Demonstration

### How It Works

ArgoCD continuously monitors the Git repository and automatically synchronizes changes:

1. **Monitoring**: ArgoCD polls the Git repository every 3 minutes (default)
2. **Detection**: When changes are detected in Git, ArgoCD compares desired state with cluster state
3. **Synchronization**: ArgoCD automatically applies changes to match Git state
4. **Self-Healing**: If resources are modified outside of Git, ArgoCD restores them to Git state

### Sync Policy Configuration

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources deleted from Git
    selfHeal: true   # Restore resources modified outside Git
```

### Testing Automated Sync

#### Scenario 1: Change Application Version

1. **Make a change in Git repository:**
   - Update image tag in deployment manifest
   - Commit and push to `feature/fix-for-argo-sycn` branch

2. **Observe ArgoCD:**
   ```bash
   # Watch Application status
   watch kubectl get application go-demo-app -n argocd
   
   # Check sync events
   kubectl describe application go-demo-app -n argocd | grep Events -A 10
   ```

3. **Verify synchronization:**
   - ArgoCD UI shows "OutOfSync" → "Syncing" → "Synced"
   - New pods are created with updated image
   - Old pods are terminated (if prune enabled)

#### Scenario 2: Self-Healing Test

1. **Manually modify a resource:**
   ```bash
   # Scale down deployment (if exists)
   kubectl scale deployment app --replicas=0 -n demo
   
   # Or delete a pod
   kubectl delete pod app -n demo
   ```

2. **Observe ArgoCD restore:**
   - ArgoCD detects the change
   - Automatically restores resource to Git state
   - Pod/deployment returns to desired state

3. **Verify in ArgoCD UI:**
   - Application shows sync activity
   - Resource is restored to match Git configuration

### CronJob Execution

The application includes a CronJob that executes every 5 minutes:

```bash
# Check CronJob status
kubectl get cronjob app-cronjob -n demo

# View recent job executions
kubectl get jobs -n demo --sort-by=.status.startTime | tail -5

# View job logs
kubectl logs job/app-cronjob-<timestamp> -n demo
```

**Schedule:** `*/5 * * * *` (every 5 minutes)

**Status:** Successfully executing with `batch/v1` API version (fixed from deprecated `batch/v1beta1`)

## Demo Video

A complete demonstration of the ArgoCD Application deployment, synchronization, and application functionality is available:

[![asciicast](https://asciinema.org/a/y1MR3Qzlm7DOdYgQ.svg)](https://asciinema.org/a/y1MR3Qzlm7DOdYgQ)

**Video Link:** https://asciinema.org/a/y1MR3Qzlm7DOdYgQ

The demo shows:
- ArgoCD status and configuration
- Application sync status
- Deployed resources overview
- Application pod details and logs
- Port forwarding setup
- API endpoint testing with curl
- CronJob execution status

### Running the Demo Locally

To record your own demo:

```bash
cd demo
./demo-argocd-app.sh
```

This will create `demo-argocd-app.cast` file that can be played or uploaded to asciinema.org.

## Troubleshooting

### Application Status: Degraded

The Application may show `Degraded` health status due to some demo pods having image pull issues. This is expected because:

- Some pods reference images from `gcr.io/smartcity-gl/` that may not be publicly accessible
- Some pods require secrets that don't exist (demo purposes)
- The main application pod (`app`) works correctly

**This does not affect the core functionality demonstration.**

### Port Forwarding Issues

If port 8082 is already in use:

```bash
# Check what's using the port
lsof -ti:8082

# Use a different port
kubectl port-forward pod/app -n demo 8083:8080
```

### Sync Not Working

If Application is not syncing:

```bash
# Check Application status
kubectl describe application go-demo-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50

# Force sync
kubectl patch application go-demo-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### CronJob API Version Error

If you see errors about `batch/v1beta1`:

- Ensure you're using the forked repository: `https://github.com/YegorMaksymchuk/go-demo-app`
- Ensure branch is `feature/fix-for-argo-sycn`
- The fix updates CronJob to use `batch/v1` API version

## Summary

### What Was Achieved

✅ **ArgoCD Application** created and configured  
✅ **Automated synchronization** enabled with prune and self-healing  
✅ **Application deployed** successfully in `demo` namespace  
✅ **Main application pod** running and accessible  
✅ **API endpoints** tested and working  
✅ **CronJob** executing successfully with fixed API version  
✅ **GitOps workflow** demonstrated end-to-end  

### Key Features Demonstrated

1. **GitOps Workflow**: Git repository → ArgoCD → Kubernetes cluster
2. **Automated Sync**: Changes in Git automatically deployed
3. **Self-Healing**: Resources restored to Git state if modified
4. **Application Functionality**: API endpoints accessible and working
5. **CronJob Management**: Scheduled jobs executing successfully

### Access Points

- **ArgoCD UI**: http://localhost:8080
- **Application API**: http://localhost:8082 (via port-forward)
- **Repository**: https://github.com/YegorMaksymchuk/go-demo-app (branch: `feature/fix-for-argo-sycn`)

### Next Steps

For production deployment:
1. Set up proper secrets and configmaps
2. Configure Ingress or LoadBalancer for external access
3. Set up monitoring and alerting
4. Implement proper CI/CD pipeline
5. Add resource limits and requests
6. Configure backup and disaster recovery

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [go-demo-app Repository](https://github.com/YegorMaksymchuk/go-demo-app)
- [k3d Documentation](https://k3d.io/)
- [Kubernetes CronJob API Migration](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#cronjob-v123)

---

**Status**: ✅ MVP Complete  
**Last Updated**: 2026-01-22  
**Demo Video**: [View on asciinema.org](https://asciinema.org/a/y1MR3Qzlm7DOdYgQ)
