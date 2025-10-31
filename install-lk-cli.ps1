# LiveKit CLI Installation Script for Windows
Write-Host "Installing LiveKit CLI on Windows..." -ForegroundColor Green

# Download LiveKit CLI for Windows
$downloadUrl = "https://github.com/livekit/livekit-cli/releases/latest/download/livekit-cli_windows_amd64.zip"
$downloadPath = "$env:TEMP\livekit-cli.zip"
$extractPath = "$env:TEMP\livekit-cli"
$installPath = "$env:LOCALAPPDATA\livekit"

Write-Host "Downloading LiveKit CLI..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
    Write-Host "Download completed" -ForegroundColor Green
} catch {
    Write-Host "Download failed. Trying alternative method..." -ForegroundColor Yellow
    # Try with GitHub releases API
    $apiUrl = "https://api.github.com/repos/livekit/livekit-cli/releases/latest"
    $release = Invoke-RestMethod -Uri $apiUrl
    $asset = $release.assets | Where-Object { $_.name -like "*windows*amd64*" }
    if ($asset) {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath
        Write-Host "Download completed via API" -ForegroundColor Green
    } else {
        Write-Host "Could not find Windows release" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Extracting CLI..."
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $downloadPath -DestinationPath $extractPath

Write-Host "Installing to $installPath..."
if (!(Test-Path $installPath)) { New-Item -ItemType Directory -Path $installPath -Force }

# Find the CLI executable
$cliExe = Get-ChildItem -Path $extractPath -Name "livekit-cli.exe" -Recurse
if ($cliExe) {
    Copy-Item -Path "$extractPath\$cliExe" -Destination "$installPath\lk.exe" -Force
    Write-Host "CLI installed as lk.exe" -ForegroundColor Green
} else {
    # Try to find lk.exe instead
    $cliExe = Get-ChildItem -Path $extractPath -Name "lk.exe" -Recurse
    if ($cliExe) {
        Copy-Item -Path "$extractPath\$cliExe" -Destination "$installPath\lk.exe" -Force
        Write-Host "CLI installed as lk.exe" -ForegroundColor Green
    } else {
        Write-Host "CLI executable not found in archive" -ForegroundColor Red
        Write-Host "Available files:"
        Get-ChildItem -Path $extractPath -Recurse | Select-Object Name
        exit 1
    }
}

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$installPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$installPath", "User")
    Write-Host "Added to PATH (restart terminal to use)" -ForegroundColor Green
}

# Test installation
Write-Host "Testing installation..."
try {
    & "$installPath\lk.exe" --version
    Write-Host "LiveKit CLI working!" -ForegroundColor Green
} catch {
    Write-Host "CLI installed but test failed. May need terminal restart." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Usage: lk --version" -ForegroundColor Yellow
Write-Host "Restart your PowerShell terminal to use lk command" -ForegroundColor Cyan

# Cleanup
Remove-Item $downloadPath -Force
Remove-Item $extractPath -Recurse -Force