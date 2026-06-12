# preflight.ps1
# One-stop verification that the project is ready to demo.
# Run from the repo root: .\scripts\preflight.ps1
#
# Output is a list of checks; each prints either OK or FAIL with a remedy.

$ErrorActionPreference = "Continue"
Set-Location (Resolve-Path "$PSScriptRoot\..")

$global:Failures = @()
function Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Test,
        [string] $Remedy = ""
    )
    Write-Host -NoNewline ("{0,-50} " -f $Name)
    try {
        $ok = & $Test
        if ($ok) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            $global:Failures += [pscustomobject]@{ Name = $Name; Remedy = $Remedy }
        }
    } catch {
        Write-Host "FAIL ($($_.Exception.Message.Split([char]10)[0]))" -ForegroundColor Red
        $global:Failures += [pscustomobject]@{ Name = $Name; Remedy = $Remedy }
    }
}

# Refresh PATH so docker / kubectl picked up after fresh install of Docker Desktop
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

Write-Host "`n=== TravelWise pre-flight ===`n" -ForegroundColor Cyan

# 1. Tooling
Check "python on PATH" { $null -ne (Get-Command python -ErrorAction SilentlyContinue) } `
      "Install Python 3.11 from python.org and re-open the terminal."

Check "git on PATH" { $null -ne (Get-Command git -ErrorAction SilentlyContinue) } `
      "Install Git from git-scm.com."

Check "docker on PATH" { $null -ne (Get-Command docker -ErrorAction SilentlyContinue) } `
      "Install Docker Desktop and ensure it is running."

Check "Docker daemon reachable" { (& docker info --format '{{.ServerVersion}}' 2>$null) -ne $null } `
      "Open Docker Desktop and wait for the whale icon to stop animating."

Check "kubectl on PATH" { $null -ne (Get-Command kubectl -ErrorAction SilentlyContinue) } `
      "Enable Kubernetes inside Docker Desktop (Settings -> Kubernetes -> Enable -> Apply)."

Check "Kubernetes context reachable" { (& kubectl version --client=false --request-timeout=5s 2>$null) -match 'Server Version' } `
      "Wait until Docker Desktop shows the Kubernetes status as Running."

# 2. Trained artefacts
Check "random_forest.pkl present" { Test-Path "Flight Prediction/random_forest.pkl" } `
      "Run: python `"Flight Prediction/train_model.py`""
Check "scaling.pkl present" { Test-Path "Flight Prediction/scaling.pkl" } `
      "Run: python `"Flight Prediction/train_model.py`""
Check "feature_columns.json present" { Test-Path "Flight Prediction/feature_columns.json" } `
      "Run: python `"Flight Prediction/train_model.py`""
Check "gender_model.pkl present" { Test-Path "Gender/gender_model.pkl" } `
      "Run: python Gender/train_model.py"
Check "company_encoder.pkl present" { (Test-Path "Gender/company_encoder.pkl") -and ((Get-Item "Gender/company_encoder.pkl").Length -gt 0) } `
      "Run: python Gender/train_model.py"

# 3. Pytest sanity
Check "pytest 6 passed" {
    Push-Location "Flight Prediction"
    try {
        $out = & python -m pytest tests/ -q 2>&1 | Out-String
        $out -match 'passed'
    } finally { Pop-Location }
} "Read the pytest output above for the failing test."

# 4. CI status
Check "Latest GitHub Actions run is success" {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) { return $false }
    $status = & gh run list -R zohaibsheikh007/Travel-MLOps-Capstone -L 1 --json status,conclusion --jq '.[0].conclusion' 2>$null
    $status -eq 'success'
} "Visit the Actions tab and re-run the latest workflow."

# 5. Docker Hub image reachable
Check "Image exists on Docker Hub" {
    try {
        $r = Invoke-RestMethod 'https://hub.docker.com/v2/repositories/sheikh007/flight-price-api/tags/?page_size=1' -TimeoutSec 8
        $r.results.Count -ge 1
    } catch { $false }
} "Confirm the GitHub Action's docker job has succeeded at least once."

# 6. Demo ports: ensure each port is either FREE (ready for demo) or already
#    serving the demo's /health endpoint. Anything else (an unrelated process
#    squatting on that port) is a real conflict.
$demoPorts = @(
    @{ Port = 8000;  Url = 'http://localhost:8000/health';  Name = 'Flask local' },
    @{ Port = 8001;  Url = 'http://localhost:8001/health';  Name = 'Docker container' },
    @{ Port = 30007; Url = 'http://localhost:30007/health'; Name = 'Kubernetes NodePort' },
    @{ Port = 8080;  Url = 'http://localhost:8080/';        Name = 'Airflow UI' },
    @{ Port = 5000;  Url = 'http://localhost:5000/';        Name = 'MLflow UI' },
    @{ Port = 8501;  Url = 'http://localhost:8501/';        Name = 'Streamlit gender' },
    @{ Port = 8502;  Url = 'http://localhost:8502/';        Name = 'Streamlit hotel' }
)
foreach ($d in $demoPorts) {
    Check ("Port $($d.Port) ($($d.Name)) free or serving") {
        $busy = Get-NetTCPConnection -State Listen -LocalPort $d.Port -ErrorAction SilentlyContinue
        if (-not $busy) { return $true }
        try {
            $r = Invoke-WebRequest $d.Url -TimeoutSec 3 -UseBasicParsing
            $r.StatusCode -ge 200 -and $r.StatusCode -lt 500
        } catch { $false }
    } "Port is occupied by something other than the demo. Stop it or change the demo's port."
}

# 7. Live API smoke (informational; reports which endpoints respond)
Check "At least one API responds /health" {
    $hits = @()
    foreach ($u in 'http://localhost:8000/health','http://localhost:8001/health','http://localhost:30007/health') {
        try {
            $r = Invoke-WebRequest $u -TimeoutSec 3 -UseBasicParsing
            if ($r.StatusCode -eq 200) { $hits += $u }
        } catch {}
    }
    Write-Host -NoNewline (" hits=$($hits.Count) ")
    $hits.Count -ge 1
} "Start one of: python Flight_Price.py / docker run flight-api / kubectl apply -f."

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($Failures.Count -eq 0) {
    Write-Host "All checks OK. You are ready to record." -ForegroundColor Green
} else {
    Write-Host "$($Failures.Count) check(s) failed. Fix them before recording:" -ForegroundColor Yellow
    $Failures | ForEach-Object { Write-Host (" - {0,-45} {1}" -f $_.Name, $_.Remedy) }
}
Write-Host ""
exit $Failures.Count
