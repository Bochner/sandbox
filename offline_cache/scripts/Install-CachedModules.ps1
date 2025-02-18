# This script installs cached PowerShell modules in an offline environment
[CmdletBinding()]
param(
    [Parameter()]
    [string]$CachePath = "$(Split-Path -Parent (Split-Path -Parent $PSScriptRoot))"
)

$ErrorActionPreference = "Stop"
$modulesPath = Join-Path $CachePath "powershell-modules/modules"

# Verify cache directory exists
if (-not (Test-Path $modulesPath)) {
    throw "Module cache directory not found at: $modulesPath"
}

# Unregister existing OfflineRepo if it exists
if (Get-PSRepository -Name "OfflineRepo" -ErrorAction SilentlyContinue) {
    Unregister-PSRepository -Name "OfflineRepo"
}

# Register local offline repository
Write-Host "Registering offline repository from: $modulesPath"
Register-PSRepository -Name "OfflineRepo" -SourceLocation $modulesPath -InstallationPolicy Trusted

# Install modules from cache
Get-ChildItem -Path $modulesPath -Directory | ForEach-Object {
    Write-Host "Installing module: $($_.Name)"
    try {
        Install-Module -Name $_.Name -Repository "OfflineRepo" -Force -AllowClobber
        Write-Host "Successfully installed: $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install module $($_.Name): $_"
    }
}

# Clean up repository registration
Write-Host "Cleaning up repository registration..."
Unregister-PSRepository -Name "OfflineRepo" -ErrorAction SilentlyContinue