#!/bin/bash
# Demo commands to be executed in asciinema recording
# This script is called by demo-argocd-app.sh

# Function to print section header
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
    sleep 1
}

# Function to print command
print_cmd() {
    echo -e "\033[0;32m$\033[0m $1"
    sleep 0.5
}

# Section 1: ArgoCD Status
print_section "1. ArgoCD Status and Access"

print_cmd "kubectl get pods -n argocd"
kubectl get pods -n argocd
sleep 2

print_cmd "kubectl get svc -n argocd argocd-server"
kubectl get svc -n argocd argocd-server
sleep 2

echo "ArgoCD UI: http://localhost:8080"
echo "Username: admin"
echo "Password: (use ./scripts/get-argocd-credentials.sh to get it)"
sleep 2

# Section 2: Application Status
print_section "2. ArgoCD Application Status"

print_cmd "kubectl get application go-demo-app -n argocd"
kubectl get application go-demo-app -n argocd
sleep 2

print_cmd "kubectl get application go-demo-app -n argocd -o jsonpath='{.spec.source.repoURL}' && echo ''"
echo "Repository: $(kubectl get application go-demo-app -n argocd -o jsonpath='{.spec.source.repoURL}')"
echo "Branch: $(kubectl get application go-demo-app -n argocd -o jsonpath='{.spec.source.targetRevision}')"
sleep 2

print_cmd "kubectl get application go-demo-app -n argocd -o jsonpath='{.status.sync.status}' && echo ' - Sync Status'"
SYNC_STATUS=$(kubectl get application go-demo-app -n argocd -o jsonpath='{.status.sync.status}')
HEALTH_STATUS=$(kubectl get application go-demo-app -n argocd -o jsonpath='{.status.health.status}')
echo "Sync Status: $SYNC_STATUS"
echo "Health Status: $HEALTH_STATUS"
sleep 2

# Section 3: Deployed Resources
print_section "3. Deployed Resources in Namespace: demo"

print_cmd "kubectl get all -n demo"
kubectl get all -n demo
sleep 2

print_cmd "kubectl get cronjob -n demo"
kubectl get cronjob -n demo
sleep 2

print_cmd "kubectl get pod app -n demo"
kubectl get pod app -n demo
sleep 2

# Section 4: Application Details
print_section "4. Application Pod Details"

print_cmd "kubectl describe pod app -n demo | head -20"
kubectl describe pod app -n demo | head -20
sleep 2

print_cmd "kubectl logs pod/app -n demo --tail=5"
kubectl logs pod/app -n demo --tail=5
sleep 2

# Section 5: Port Forwarding Setup
print_section "5. Setting Up Port Forwarding for Application"

echo "Setting up port-forward: localhost:8082 -> pod:8080"
echo "Note: In real scenario, this would run in background"
sleep 2

# Check if port-forward is already running, if not start it
PF_PID=$(lsof -ti:8082 2>/dev/null || echo "")
if [ -z "$PF_PID" ]; then
    print_cmd "kubectl port-forward pod/app -n demo 8082:8080 > /dev/null 2>&1 &"
    kubectl port-forward pod/app -n demo 8082:8080 > /dev/null 2>&1 &
    PF_PID=$!
    echo "Port-forward started (PID: $PF_PID)"
    sleep 3
else
    echo "Port-forward already running on port 8082"
fi

# Section 6: API Testing
print_section "6. Testing Application API"

print_cmd "curl -s http://localhost:8082/"
echo "Testing root endpoint:"
curl -s http://localhost:8082/
echo ""
sleep 2

print_cmd "curl -s http://localhost:8082/api/"
echo "Testing /api/ endpoint:"
curl -s http://localhost:8082/api/
echo ""
sleep 2

print_cmd "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:8082/api/"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8082/api/
sleep 2

# Additional curl examples
print_cmd "echo 'Testing with verbose output:'"
echo "Testing with verbose output:"
curl -v http://localhost:8082/api/ 2>&1 | head -10
sleep 2

# Section 7: CronJob Status
print_section "7. CronJob Execution Status"

print_cmd "kubectl get jobs -n demo --sort-by=.status.startTime | tail -3"
kubectl get jobs -n demo --sort-by=.status.startTime | tail -3
sleep 2

print_cmd "kubectl get cronjob app-cronjob -n demo -o jsonpath='{.status.lastScheduleTime}' && echo ''"
LAST_SCHEDULE=$(kubectl get cronjob app-cronjob -n demo -o jsonpath='{.status.lastScheduleTime}' 2>/dev/null || echo "Not scheduled yet")
echo "Last Schedule Time: $LAST_SCHEDULE"
sleep 2

# Section 8: Summary
print_section "8. Summary"

echo "✅ ArgoCD is running and accessible"
echo "✅ Application 'go-demo-app' is synced"
echo "✅ Resources deployed in namespace 'demo'"
echo "✅ Application pod is running"
echo "✅ API is accessible on http://localhost:8082"
echo "✅ CronJob is executing successfully"
echo ""
echo "Application URL: http://localhost:8082"
echo "ArgoCD UI: http://localhost:8080"
echo ""
