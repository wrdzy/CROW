# =============================================================================
# Push CROWui-deepwoken and CROWUI to GitHub (wrdyz)
# Run in PowerShell: .\push-repos.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$user = "wrdyz"
$base = "c:\Users\wrdyz\Documents\Robloxstuff"

# -----------------------------------------------------------------------------
# 1. Find GitHub CLI (gh)
# -----------------------------------------------------------------------------
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    $ghPath = "C:\Program Files\GitHub CLI\gh.exe"
    if (Test-Path $ghPath) { $gh = $ghPath } else {
        Write-Host "Installing GitHub CLI (gh)..." -ForegroundColor Cyan
        winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
        Write-Host "Please close and reopen PowerShell, then run this script again." -ForegroundColor Yellow
        exit 0
    }
} else { $gh = $gh.Source }

# -----------------------------------------------------------------------------
# 2. Require login
# -----------------------------------------------------------------------------
& $gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub CLI is not logged in. Running: gh auth login" -ForegroundColor Yellow
    & $gh auth login
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# -----------------------------------------------------------------------------
# 3. CROWui-deepwoken
# -----------------------------------------------------------------------------
$deepwoken = Join-Path $base "CROWui-deepwoken"
Set-Location $deepwoken

if (-not (git remote get-url origin 2>$null)) {
    Write-Host "Creating repo wrdyz/CROWui-deepwoken and pushing..." -ForegroundColor Cyan
    & $gh repo create CROWui-deepwoken --private --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Repo may already exist. Adding remote and pushing..." -ForegroundColor Yellow
        git remote add origin "https://github.com/$user/CROWui-deepwoken.git"
        git push -u origin main
    }
} else {
    Write-Host "Pushing CROWui-deepwoken..." -ForegroundColor Cyan
    git push -u origin main
}

# -----------------------------------------------------------------------------
# 4. CROWUI
# -----------------------------------------------------------------------------
$crowui = Join-Path $base "CROWUI"
Set-Location $crowui

if (-not (git remote get-url origin 2>$null)) {
    Write-Host "Creating repo wrdyz/CROWUI and pushing..." -ForegroundColor Cyan
    & $gh repo create CROWUI --private --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Repo may already exist. Adding remote and pushing..." -ForegroundColor Yellow
        git remote add origin "https://github.com/$user/CROWUI.git"
        git push -u origin main
    }
} else {
    Write-Host "Pushing CROWUI..." -ForegroundColor Cyan
    git push -u origin main
}

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Done. Repos:" -ForegroundColor Green
Write-Host "  https://github.com/$user/CROWui-deepwoken"
Write-Host "  https://github.com/$user/CROWUI"
