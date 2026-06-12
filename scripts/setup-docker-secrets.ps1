# Adds DOCKER_USERNAME and DOCKER_PASSWORD as GitHub Actions secrets
# and triggers a fresh workflow run.
#
# Usage:
#   .\scripts\setup-docker-secrets.ps1 -User <your-dockerhub-username> -Token <your-dockerhub-token>

param(
    [Parameter(Mandatory=$true)] [string]$User,
    [Parameter(Mandatory=$true)] [string]$Token,
    [string]$Owner = "zohaibsheikh007",
    [string]$Repo  = "Travel-MLOps-Capstone"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$gh = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) {
    $gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
}
if (-not $gh) { Write-Host "gh not found." -ForegroundColor Red; exit 1 }

Write-Host "==> Adding DOCKER_USERNAME secret..."
$User  | & $gh secret set DOCKER_USERNAME --repo "$Owner/$Repo"

Write-Host "==> Adding DOCKER_PASSWORD secret..."
$Token | & $gh secret set DOCKER_PASSWORD --repo "$Owner/$Repo"

Write-Host "==> Triggering a fresh workflow run..."
& $gh workflow run "Build and Deploy Flight Price API" --repo "$Owner/$Repo" --ref main 2>$null

Start-Sleep -Seconds 4
Write-Host ""
Write-Host "==> Latest runs:"
& $gh run list --repo "$Owner/$Repo" -L 3

Write-Host ""
Write-Host "==> Watch live: https://github.com/$Owner/$Repo/actions"
