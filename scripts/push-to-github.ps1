# Push this project to GitHub.
#
# Usage:  .\scripts\push-to-github.ps1
#
# Prerequisites: install GitHub CLI from https://cli.github.com/  (winget install GitHub.cli)

param(
    [string]$Owner    = "zohaibsheikh007",
    [string]$RepoName = "Travel-MLOps-Capstone",
    [switch]$Private
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "==> Project: $Owner/$RepoName"

# 1. Make sure git knows who we are.
$cfgName  = (git config user.name)  2>$null
$cfgEmail = (git config user.email) 2>$null
if (-not $cfgName -or -not $cfgEmail) {
    Write-Host "git user.name / user.email is not configured."
    Write-Host "Run:  git config --global user.name 'Your Name'"
    Write-Host "      git config --global user.email 'you@example.com'"
    exit 1
}
Write-Host "==> Git author: $cfgName <$cfgEmail>"

# 2. Check that gh is installed.
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host ""
    Write-Host "GitHub CLI (gh) is not installed."
    Write-Host "Install it with:   winget install GitHub.cli"
    Write-Host "Or download from:  https://cli.github.com/"
    Write-Host ""
    Write-Host "Manual fallback (do this in a browser):"
    Write-Host "  1. Go to https://github.com/new"
    Write-Host "  2. Repository name: $RepoName"
    Write-Host "  3. Public, do NOT initialise with README/license/.gitignore"
    Write-Host "  4. Click Create"
    Write-Host "  5. Then run these in PowerShell:"
    Write-Host "       git remote remove origin 2>`$null"
    Write-Host "       git remote add origin https://github.com/$Owner/$RepoName.git"
    Write-Host "       git push -u origin main"
    exit 1
}

# 3. Authenticate if needed.
gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "==> You are not logged in to GitHub. Starting browser-based login..."
    gh auth login --web --git-protocol https
    if ($LASTEXITCODE -ne 0) { Write-Host "gh auth login failed."; exit 1 }
}

# 4. Create the repo (idempotent).
$visibility = if ($Private) { "--private" } else { "--public" }
gh repo view "$Owner/$RepoName" 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "==> Creating repository $Owner/$RepoName ($visibility)"
    gh repo create "$Owner/$RepoName" $visibility --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) { Write-Host "Failed to create repo."; exit 1 }
} else {
    Write-Host "==> Repository already exists. Pushing latest commits..."
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$Owner/$RepoName.git"
    git push -u origin main
}

Write-Host ""
Write-Host "==> Done!"
Write-Host "    Repository:  https://github.com/$Owner/$RepoName"
Write-Host "    Actions:     https://github.com/$Owner/$RepoName/actions"
