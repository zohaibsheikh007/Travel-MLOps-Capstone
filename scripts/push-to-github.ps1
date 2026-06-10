# Push the project to GitHub.
#
# Usage:        .\scripts\push-to-github.ps1
# Or with args: .\scripts\push-to-github.ps1 -Owner zohaibsheikh007 -RepoName Travel-MLOps-Capstone

param(
    [string]$Owner    = "zohaibsheikh007",
    [string]$RepoName = "Travel-MLOps-Capstone",
    [switch]$Private
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host ""
Write-Host "==> TravelWise -> GitHub"
Write-Host "    Repository:  $Owner/$RepoName"
Write-Host ""

# 1. Sanity: git is installed.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git is not installed. Install from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# 2. Sanity: git author is set.
if (-not (git config user.name)) {
    Write-Host "Setting a default git user.name (you can change it later)..."
    git config --global user.name $Owner
}
if (-not (git config user.email)) {
    Write-Host "Setting a default git user.email..."
    git config --global user.email "$Owner@users.noreply.github.com"
}

# 3. Find gh.
$ghPath = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $ghPath)) {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd) { $ghPath = $cmd.Source }
}

if (-not (Test-Path $ghPath)) {
    Write-Host "GitHub CLI (gh) is not installed."                             -ForegroundColor Yellow
    Write-Host "Quickest install:  winget install GitHub.cli"                  -ForegroundColor Yellow
    Write-Host "Then re-run this script."                                       -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual fallback (no gh required):"                              -ForegroundColor Cyan
    Write-Host "  1. Open https://github.com/new in your browser"
    Write-Host "  2. Repository name: $RepoName"
    Write-Host "  3. Public, do NOT add README/license/.gitignore"
    Write-Host "  4. Click Create"
    Write-Host "  5. Then run:"
    Write-Host "       git remote remove origin 2>`$null"
    Write-Host "       git remote add origin https://github.com/$Owner/$RepoName.git"
    Write-Host "       git push -u origin main"
    Write-Host "     (paste your GitHub username + a Personal Access Token when prompted)"
    Write-Host "     PAT: https://github.com/settings/tokens -> Generate new token (classic) -> repo scope"
    exit 1
}

# 4. Authenticate.
& $ghPath auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "==> Logging in to GitHub..."                                    -ForegroundColor Cyan
    Write-Host "    A browser window will open with a one-time code."
    Write-Host "    Copy the code shown in this terminal, paste it in the browser, click Continue."
    Write-Host ""
    & $ghPath auth login --web --git-protocol https --hostname github.com
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gh auth login failed. Try again or use the manual fallback above." -ForegroundColor Red
        exit 1
    }
}

# 5. Configure git to use gh's credential helper for github.com.
& $ghPath auth setup-git 2>$null

# 6. Create the repo (idempotent).
$visibility = if ($Private) { "--private" } else { "--public" }
& $ghPath repo view "$Owner/$RepoName" 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "==> Creating repository $Owner/$RepoName..."                    -ForegroundColor Cyan
    & $ghPath repo create "$Owner/$RepoName" $visibility --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create repo via gh. Falling back to manual remote..." -ForegroundColor Yellow
        git remote remove origin 2>$null
        git remote add origin "https://github.com/$Owner/$RepoName.git"
        git push -u origin main
    }
} else {
    Write-Host "==> Repository exists. Pushing latest commits..."
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$Owner/$RepoName.git"
    git push -u origin main
}

Write-Host ""
Write-Host "==> Pushed!" -ForegroundColor Green
Write-Host "    Repo:         https://github.com/$Owner/$RepoName"
Write-Host "    Actions:      https://github.com/$Owner/$RepoName/actions"
Write-Host "    Settings:     https://github.com/$Owner/$RepoName/settings/secrets/actions"
Write-Host ""
Write-Host "Optional: add Docker Hub secrets so the CI can push images:"
Write-Host "  - DOCKER_USERNAME"
Write-Host "  - DOCKER_PASSWORD"
