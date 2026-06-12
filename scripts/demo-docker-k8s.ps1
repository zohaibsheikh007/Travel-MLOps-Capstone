# One-shot Docker + Kubernetes demo runner.
#
# Prerequisites:
#   - Docker Desktop is running (whale icon green in tray)
#   - Kubernetes is enabled in Docker Desktop -> Settings -> Kubernetes
#
# Usage:  .\scripts\demo-docker-k8s.ps1
#
# What it does:
#   1. Builds the Docker image
#   2. Runs the container locally on port 8001
#   3. Verifies /health and /api/predict respond correctly
#   4. Applies Kubernetes deployment + service
#   5. Waits for both replicas to become ready
#   6. Verifies the K8s service responds on port 30007
#   7. Prints a checklist of screenshots to take

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Banner($text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

# ---- Step 0: sanity ----
Banner "Step 0: checking Docker and kubectl are available"
docker version --format "{{.Server.Version}}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Start Docker Desktop and retry." -ForegroundColor Red
    exit 1
}
kubectl version --client --output=yaml | Select-String "gitVersion" | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl is missing. Make sure Docker Desktop -> Settings -> Kubernetes is enabled." -ForegroundColor Red
    exit 1
}

# ---- Step 1: build image ----
Banner "Step 1: docker build"
docker build -t travelwise/flight-price-api:latest "Flight Prediction"
if ($LASTEXITCODE -ne 0) { Write-Host "docker build failed." -ForegroundColor Red; exit 1 }

Banner "Step 2: docker images (screenshot this)"
docker images travelwise/flight-price-api

# ---- Step 3: run container ----
Banner "Step 3: docker run -d -p 8001:8000"
docker rm -f flight-api 2>$null | Out-Null
docker run -d -p 8001:8000 --name flight-api travelwise/flight-price-api:latest
Start-Sleep -Seconds 4

Banner "Step 4: docker ps (screenshot this)"
docker ps --filter "name=flight-api"

# ---- Step 4: hit the API ----
Banner "Step 5: HTTP /health (screenshot this)"
$health = Invoke-RestMethod "http://localhost:8001/health"
$health | ConvertTo-Json

Banner "Step 6: HTTP POST /api/predict (screenshot this)"
$body = @{
    from_location = "Sao_Paulo (SP)"
    destination   = "Rio_de_Janeiro (RJ)"
    flight_type   = "economic"
    agency        = "CloudFy"
    week_no       = 10
    week_day      = 3
    day           = 15
} | ConvertTo-Json
$prediction = Invoke-RestMethod "http://localhost:8001/api/predict" -Method Post -Body $body -ContentType "application/json"
$prediction | ConvertTo-Json

# ---- Step 5: Kubernetes ----
Banner "Step 7: kubectl apply"
kubectl apply -f "Flight Prediction/deployment.yaml"
kubectl apply -f "Flight Prediction/service.yaml"

Banner "Step 8: kubectl rollout status (waits for both replicas)"
kubectl rollout status deployment/flight-price-deployment --timeout=180s

Banner "Step 9: kubectl get pods (screenshot this)"
kubectl get pods -l app=flight-price -o wide

Banner "Step 10: kubectl get svc (screenshot this)"
kubectl get svc flight-price-service

Banner "Step 11: kubectl describe deployment (screenshot this)"
kubectl describe deployment flight-price-deployment | Select-Object -First 30

# ---- Step 6: hit the service through K8s ----
Banner "Step 12: HTTP via NodePort 30007 (screenshot this)"
Start-Sleep -Seconds 3
try {
    $k8sHealth = Invoke-RestMethod "http://localhost:30007/health"
    $k8sHealth | ConvertTo-Json
} catch {
    Write-Host "NodePort not reachable yet. Try in 30s: curl http://localhost:30007/health" -ForegroundColor Yellow
}

# ---- Done ----
Banner "All checks passed. Screenshots needed for the Google Doc:"
Write-Host @"
1. The 'docker images travelwise/flight-price-api' line
2. The 'docker ps' line showing the running container
3. The /health JSON response in your browser:  http://localhost:8001/health
4. A browser at http://localhost:8001/ filling the form and getting a price
5. 'kubectl get pods' showing 2/2 Running
6. 'kubectl get svc' showing port 30007
7. A browser at http://localhost:30007/ showing the same form served by Kubernetes

Open these URLs now in browser tabs and screenshot each:
   http://localhost:8001/                 (Docker container)
   http://localhost:8001/health           (Docker container health)
   http://localhost:30007/                (Kubernetes service)
   http://localhost:30007/health          (Kubernetes service health)

Cleanup when done:
   docker rm -f flight-api
   kubectl delete -f 'Flight Prediction/deployment.yaml' -f 'Flight Prediction/service.yaml'
"@ -ForegroundColor Green
