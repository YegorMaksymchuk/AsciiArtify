# ArgoCD Application Demo

This demo script demonstrates the complete ArgoCD GitOps workflow with the go-demo-app application.

## Overview

The demo shows:
1. ArgoCD status and access information
2. Application sync status and configuration
3. Deployed resources in the demo namespace
4. Application pod details and logs
5. Port forwarding setup for application access
6. API testing with curl examples
7. CronJob execution status
8. Summary of the deployment

## Prerequisites

- k3d cluster running
- ArgoCD installed and running
- Application `go-demo-app` created and synced
- asciinema installed (`brew install asciinema`)

## Usage

### Record Demo

```bash
cd 04_Kubernetes/01_Task/demo
./demo-argocd-app.sh
```

The script will:
- Check all prerequisites
- Start asciinema recording
- Execute demo commands
- Save recording to `demo-argocd-app.cast`

### Play Demo

```bash
asciinema play demo-argocd-app.cast
```

### Upload Demo

```bash
asciinema upload demo-argocd-app.cast
```

## Demo Sections

### 1. ArgoCD Status and Access
- Shows ArgoCD pods status
- Displays ArgoCD server service
- Provides UI access information

### 2. ArgoCD Application Status
- Shows Application sync and health status
- Displays repository URL and branch
- Verifies GitOps configuration

### 3. Deployed Resources
- Lists all resources in demo namespace
- Shows CronJob status
- Displays application pod status

### 4. Application Pod Details
- Shows pod description
- Displays application logs

### 5. Port Forwarding Setup
- Sets up port-forward for application access
- Maps localhost:8082 to pod:8080

### 6. API Testing
- Tests root endpoint (`/`)
- Tests API endpoint (`/api/`)
- Shows HTTP status codes
- Demonstrates curl usage

### 7. CronJob Execution Status
- Shows recent job executions
- Displays last schedule time

### 8. Summary
- Provides overview of all components
- Lists access URLs

## Files

- `demo-argocd-app.sh` - Main demo script (checks prerequisites, starts recording)
- `demo-argocd-app-commands.sh` - Commands executed during recording
- `demo-argocd-app.cast` - Recorded demo file (created after running)

## Notes

- Port 8082 is used for application to avoid conflict with ArgoCD on port 8080
- The demo assumes Application is already synced
- Port-forward is started automatically if not already running
- Demo takes approximately 2-3 minutes to complete

## Troubleshooting

If demo fails:
1. Ensure ArgoCD is running: `kubectl get pods -n argocd`
2. Ensure Application exists: `kubectl get application go-demo-app -n argocd`
3. Ensure application pod is running: `kubectl get pod app -n demo`
4. Check port 8082 is available: `lsof -ti:8082`
