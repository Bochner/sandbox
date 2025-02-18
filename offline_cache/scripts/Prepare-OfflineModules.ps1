#!/usr/bin/env pwsh
# Pre-download PowerShell modules for offline installation on Windows hosts
# Run this script on a Windows machine with internet access to prepare the module cache

[CmdletBinding()]
param(
    [Parameter()]
    [string]$CacheDirectory = "cache/powershell-modules"
)

$modules = @(
    # Base PowerShell modules
    @{ Name = "PowerShellGet"; RequiredVersion = "2.2.5" }
    @{ Name = "PackageManagement"; RequiredVersion = "1.4.7" }
    
    # AD and LAPS modules
    @{ Name = "ActiveDirectory" }
    @{ Name = "AdmPwd.PS" }  # LAPS module
    
    # ADCS modules
    @{ Name = "ADCSTemplate" }
    @{ Name = "xAdcsDeployment" }
    
    # Configuration modules
    @{ Name = "xActiveDirectory" }
    @{ Name = "SecurityPolicyDsc" }
    @{ Name = "NetworkingDsc" }
    @{ Name = "ComputerManagementDsc" }
)

# Ensure cache directory exists
$modulesPath = Join-Path $CacheDirectory "modules"
$providerPath = Join-Path $CacheDirectory "providers"
New-Item -ItemType Directory -Path $modulesPath, $providerPath -Force

# Register PSGallery if not present
if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default -InstallationPolicy Trusted
}

# Save NuGet provider
$nuget = Get-PackageProvider -Name NuGet -ListAvailable | Select-Object -First 1
if ($nuget) {
    $source = Split-Path $nuget.Source -Parent
    Copy-Item -Path $source -Destination $providerPath -Recurse -Force
}

# Download modules
foreach ($module in $modules) {
    Write-Host "Downloading module: $($module.Name)"
    if ($module.RequiredVersion) {
        Save-Module -Name $module.Name -Path $modulesPath -RequiredVersion $module.RequiredVersion -Repository PSGallery
    } else {
        Save-Module -Name $module.Name -Path $modulesPath -Repository PSGallery
    }
}