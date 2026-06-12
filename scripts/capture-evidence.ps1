# capture-evidence.ps1
# Saves command-line evidence (curl, pytest, kubectl, docker) into
# screenshots/evidence/ as plain text. Useful as an appendix in the Google Doc
# and as a quick sanity check that everything works.

$ErrorActionPreference = "Continue"
Set-Location (Resolve-Path "$PSScriptRoot\..")

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

$EvidenceDir = "screenshots/evidence"
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null

function Save-Evidence {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Run
    )
    $path = Join-Path $EvidenceDir "$Name.txt"
    "=== $Name ===" | Out-File $path -Encoding utf8
    "captured: $(Get-Date -Format o)" | Out-File $path -Append -Encoding utf8
    "" | Out-File $path -Append -Encoding utf8
    try {
        & $Run *>&1 | Out-File $path -Append -Encoding utf8
        Write-Host (" + {0}" -f $path) -ForegroundColor Green
    } catch {
        "ERROR: $($_.Exception.Message)" | Out-File $path -Append -Encoding utf8
        Write-Host (" - {0} (failed)" -f $path) -ForegroundColor Yellow
    }
}

Write-Host "`n=== Capturing evidence into $EvidenceDir ===`n" -ForegroundColor Cyan

# 1. Pytest output
Save-Evidence "01-pytest" {
    Push-Location "Flight Prediction"
    try { python -m pytest tests/ -v } finally { Pop-Location }
}

# 2. Live API health + prediction (best-effort, picks first port that responds)
$apiBase = $null
foreach ($u in 'http://localhost:8000','http://localhost:8001','http://localhost:30007') {
    try {
        $r = Invoke-WebRequest "$u/health" -TimeoutSec 3 -UseBasicParsing
        if ($r.StatusCode -eq 200) { $apiBase = $u; break }
    } catch {}
}

if ($apiBase) {
    Save-Evidence "02-api-health" {
        "GET $apiBase/health"
        Invoke-RestMethod "$apiBase/health" | ConvertTo-Json
    }
    Save-Evidence "03-api-predict" {
        "POST $apiBase/api/predict"
        $body = @{
            from_location = "Sao_Paulo (SP)"
            destination   = "Rio_de_Janeiro (RJ)"
            flight_type   = "economic"
            agency        = "CloudFy"
            week_no       = 10
            week_day      = 3
            day           = 15
        } | ConvertTo-Json
        $body
        "---"
        Invoke-RestMethod "$apiBase/api/predict" -Method POST -Body $body -ContentType "application/json" | ConvertTo-Json
    }
} else {
    Save-Evidence "02-api-health" { "API not running on 8000/8001/30007. Start one of the demos and re-run this script." }
}

# 3. Docker
Save-Evidence "04-docker-images" { docker images travelwise/flight-price-api; "---"; docker images sheikh007/flight-price-api }
Save-Evidence "05-docker-ps"     { docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" }

# 4. Kubernetes
Save-Evidence "06-kubectl-pods" { kubectl get pods -o wide }
Save-Evidence "07-kubectl-svc"  { kubectl get svc }
Save-Evidence "08-kubectl-deployments" { kubectl get deployments }

# 5. CI status
Save-Evidence "09-gh-runs" {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh run list -R zohaibsheikh007/Travel-MLOps-Capstone -L 5
    } else {
        "gh CLI not installed; visit https://github.com/zohaibsheikh007/Travel-MLOps-Capstone/actions"
    }
}

# 6. Git history
Save-Evidence "10-git-log" { git log --oneline -15 }

# 7. K8s manifest tag
Save-Evidence "11-deployment-image-tag" { Select-String -Path "Flight Prediction\deployment.yaml" -Pattern 'image:' }

# 8. Model leaderboard if present
if (Test-Path "Flight Prediction\model_leaderboard.csv") {
    Save-Evidence "12-model-leaderboard" { Get-Content "Flight Prediction\model_leaderboard.csv" }
}

# Concatenate all into one master file for easy paste-into-doc
$all = Join-Path $EvidenceDir "all-evidence.txt"
"# TravelWise - Evidence appendix" | Out-File $all -Encoding utf8
"generated: $(Get-Date -Format o)" | Out-File $all -Append -Encoding utf8
"" | Out-File $all -Append -Encoding utf8
Get-ChildItem $EvidenceDir -Filter '*.txt' | Where-Object { $_.Name -ne 'all-evidence.txt' } | Sort-Object Name | ForEach-Object {
    Get-Content $_.FullName | Out-File $all -Append -Encoding utf8
    "" | Out-File $all -Append -Encoding utf8
}

Write-Host "`nDone. Open $EvidenceDir to review, or paste $all into the Google Doc appendix.`n" -ForegroundColor Cyan
