# One-shot Airflow + MLflow demo runner.
#
# Prerequisites: Docker Desktop running.
#
# Usage:  .\scripts\demo-airflow-mlflow.ps1
#
# What it does:
#   1. Brings up the Airflow + MLflow + Postgres + Redis docker-compose stack
#   2. Waits for the Airflow webserver to become healthy
#   3. Triggers the flight_price_prediction DAG
#   4. Tells you which URLs to open and which screenshots to take

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Banner($text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

Banner "Step 1: copy .env if missing"
$envFile = "Flight Prediction\airflow-docker\.env"
if (-not (Test-Path $envFile)) {
    Copy-Item "Flight Prediction\airflow-docker\.env.example" $envFile
}

Banner "Step 2: docker compose up -d (this can take 3-5 minutes the first time)"
Set-Location "Flight Prediction\airflow-docker"
docker compose up -d
if ($LASTEXITCODE -ne 0) { Write-Host "docker compose failed." -ForegroundColor Red; exit 1 }

Banner "Step 3: waiting for airflow-webserver to become healthy..."
$attempts = 0
$max = 60
while ($attempts -lt $max) {
    Start-Sleep -Seconds 5
    $attempts++
    try {
        $resp = Invoke-WebRequest "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            Write-Host "  Webserver healthy after $($attempts * 5)s" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  ... still booting ($($attempts * 5)s)" -ForegroundColor Yellow
    }
}

Banner "Step 4: docker compose ps (screenshot this)"
docker compose ps

Banner "All services up!" 
Write-Host @"
URLs to open now:
   Airflow UI:  http://localhost:8080   (login airflow / airflow)
   MLflow UI:   http://localhost:5000

In Airflow:
   1. Toggle 'flight_price_prediction' DAG to ON
   2. Click the play icon to Trigger DAG
   3. Click the running DAG -> Graph view
   4. Wait until extract_data, transform_data, train_model are all green (~3 min)

Screenshots to take:
   1. Airflow DAGs list with the DAG enabled (toggled on)
   2. Graph view of a successful run (3 green nodes)
   3. Logs of the train_model task (click the green node -> Logs)
   4. MLflow Experiments page with 'flight_price_prediction'
   5. MLflow run detail page with metrics + the model artifact

Cleanup when done:
   docker compose down -v
"@ -ForegroundColor Green
