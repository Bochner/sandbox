#!/bin/bash

# Get the absolute path to the offline_cache directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CACHE_DIR="$(dirname "${SCRIPT_DIR}")"
PROJECT_ROOT="$(dirname "${CACHE_DIR}")"

# Define cache directories
INSTALLERS_DIR="${CACHE_DIR}/installers"
COLLECTIONS_DIR="${CACHE_DIR}/ansible-collections"
PIP_DIR="${CACHE_DIR}/pip-packages"
PSMODULES_DIR="${CACHE_DIR}/powershell-modules"
EXCHANGE_DIR="${CACHE_DIR}/exchange"
SQL_DIR="${CACHE_DIR}/sql-server"
ELK_DIR="${CACHE_DIR}/elk"
WAZUH_DIR="${CACHE_DIR}/wazuh"

# Verify we're in the correct directory
if [[ ! -d "${CACHE_DIR}/scripts" ]]; then
    echo "Error: Could not locate the offline_cache directory"
    exit 1
fi

# Create cache directories
echo "Creating cache directories..."
mkdir -p "${INSTALLERS_DIR}"
mkdir -p "${COLLECTIONS_DIR}"
mkdir -p "${PIP_DIR}"
mkdir -p "${PSMODULES_DIR}/modules"
mkdir -p "${EXCHANGE_DIR}/prerequisites"
mkdir -p "${SQL_DIR}"
mkdir -p "${ELK_DIR}/server"
mkdir -p "${ELK_DIR}/windows-agent"
mkdir -p "${ELK_DIR}/linux-agent"
mkdir -p "${WAZUH_DIR}/server"
mkdir -p "${WAZUH_DIR}/windows-agent"
mkdir -p "${WAZUH_DIR}/linux-agent"

# Create PowerShell module download script
cat > "${PSMODULES_DIR}/download-modules.ps1" << 'EOF'
$ErrorActionPreference = "Stop"

# Create the modules directory if it doesn't exist
$modulesPath = Join-Path $PSScriptRoot "modules"
New-Item -ItemType Directory -Path $modulesPath -Force -ErrorAction SilentlyContinue

# Required modules with specific versions where needed
$galleryModules = @(
    @{ Name = "PowerShellGet"; RequiredVersion = "2.2.5" }
    @{ Name = "PackageManagement"; RequiredVersion = "1.4.7" }
    @{ Name = "AdmPwd.PS" }
    @{ Name = "ADCSTemplate" }
    @{ Name = "xAdcsDeployment" }
    @{ Name = "xActiveDirectory" }
    @{ Name = "SecurityPolicyDsc" }
    @{ Name = "NetworkingDsc" }
    @{ Name = "ComputerManagementDsc" }
)

# Windows-only modules that come with RSAT - we'll skip these on non-Windows
$windowsOnlyModules = @(
    "ActiveDirectory"
)

# Register PSGallery if not registered
if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
    Write-Host "Registering PSGallery..."
    Register-PSRepository -Default -InstallationPolicy Trusted
}

# Download gallery modules
foreach ($module in $galleryModules) {
    Write-Host "Downloading module: $($module.Name)"
    try {
        if ($module.RequiredVersion) {
            Save-Module -Name $module.Name -Path $modulesPath -RequiredVersion $module.RequiredVersion -Repository PSGallery -Force
        } else {
            Save-Module -Name $module.Name -Path $modulesPath -Repository PSGallery -Force
        }
    } catch {
        Write-Warning "Failed to download module $($module.Name): $_"
    }
}

# Check for Windows-only modules
foreach ($module in $windowsOnlyModules) {
    Write-Host "Note: $module is a Windows-only module that comes with RSAT - it will be installed during lab setup"
}
EOF

# Download common installers
echo "Downloading installers..."
INSTALLERS=(
    "https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi"
    "https://aka.ms/vs/15/release/vc_redist.x64.exe"
    "https://go.microsoft.com/fwlink/?linkid=2266640"
    "https://go.microsoft.com/fwlink/p/?LinkID=2195628"
    "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
    "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
)

download_with_agent() {
    local url="$1"
    local output_dir="$2"
    local filename="${3:-}"  # Optional filename parameter
    
    if [ -n "$filename" ]; then
        wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
             --no-check-certificate \
             --content-disposition \
             --tries=3 \
             --timeout=60 \
             --wait=2 \
             -O "${output_dir}/${filename}" \
             "$url" || echo "Failed to download: $url"
    else
        wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
             --no-check-certificate \
             --content-disposition \
             --tries=3 \
             --timeout=60 \
             --wait=2 \
             -P "$output_dir" \
             -nc \
             "$url" || echo "Failed to download: $url"
    fi
}

for url in "${INSTALLERS[@]}"; do
    echo "Downloading: ${url}"
    download_with_agent "$url" "${INSTALLERS_DIR}"
done

# Exchange prerequisites 
EXCHANGE_PREREQS=(
    "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
    "https://download.microsoft.com/download/8/C/2/8C2BBBAE-928B-4E43-A790-95EF76E32FEE/Exchange2019-x64-cu13.iso"
    "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
    "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"
)

for url in "${EXCHANGE_PREREQS[@]}"; do
    echo "Downloading Exchange prerequisite: ${url}"
    download_with_agent "$url" "${EXCHANGE_DIR}/prerequisites"
done

# SQL Server installers
# For SQL Server, we need to follow redirects and handle special cases
SQL_INSTALLERS=(
    "https://go.microsoft.com/fwlink/?linkid=866662|SQLServer2019.iso"
    "https://go.microsoft.com/fwlink/?linkid=2215159|SQLServer2022.iso"
    "https://go.microsoft.com/fwlink/?linkid=2014306|SSMS-Setup-ENU.exe"
)

for entry in "${SQL_INSTALLERS[@]}"; do
    IFS='|' read -r url filename <<< "$entry"
    echo "Downloading SQL Server installer: ${url} as ${filename}"
    download_with_agent "$url" "${SQL_DIR}" "${filename}"
done

# ELK components
ELK_COMPONENTS=(
    # Server components
    "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.1-linux-x86_64.tar.gz"
    "https://artifacts.elastic.co/downloads/kibana/kibana-8.11.1-linux-x86_64.tar.gz"
    "https://artifacts.elastic.co/downloads/logstash/logstash-8.11.1-linux-x86_64.tar.gz"
    # Windows agents
    "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.11.1-windows-x86_64.zip"
    "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.1-windows-x86_64.zip"
    # Linux agents
    "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.1-linux-x86_64.tar.gz"
    "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.11.1-linux-x86_64.tar.gz"
)

# Download ELK components with basic authentication if needed
for url in "${ELK_COMPONENTS[@]}"; do
    echo "Downloading ELK component: ${url}"
    if [[ $url == *"windows"* ]]; then
        download_with_agent "$url" "${ELK_DIR}/windows-agent"
    elif [[ $url == *"linux"* ]]; then
        if [[ $url == *"elasticsearch"* ]] || [[ $url == *"kibana"* ]] || [[ $url == *"logstash"* ]]; then
            download_with_agent "$url" "${ELK_DIR}/server"
        else
            download_with_agent "$url" "${ELK_DIR}/linux-agent"
        fi
    fi
done

# Wazuh components
WAZUH_COMPONENTS=(
    # Server components
    "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-manager/wazuh-manager_4.7.3-1_amd64.deb"
    "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-indexer/wazuh-indexer_4.7.3-1_amd64.deb"
    "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-dashboard/wazuh-dashboard_4.7.3-1_amd64.deb"
    # Windows agent
    "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi"
    # Linux agent
    "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.3-1_amd64.deb"
)

for url in "${WAZUH_COMPONENTS[@]}"; do
    echo "Downloading Wazuh component: ${url}"
    if [[ $url == *"windows"* ]]; then
        download_with_agent "$url" "${WAZUH_DIR}/windows-agent"
    elif [[ $url == *"agent"*".deb" ]]; then
        download_with_agent "$url" "${WAZUH_DIR}/linux-agent"
    else
        download_with_agent "$url" "${WAZUH_DIR}/server"
    fi
done

# Cache pip packages
for req_file in "${PROJECT_ROOT}/requirements.yml" "${PROJECT_ROOT}/requirements_311.yml"; do
    if [ -f "${req_file}" ]; then
        echo "Downloading pip packages from ${req_file}..."
        pip download -r "${req_file}" -d "${PIP_DIR}"
    fi
done

# Cache ansible collections
if [ -f "${PROJECT_ROOT}/ansible/requirements.yml" ]; then
    echo "Downloading ansible collections..."
    ansible-galaxy collection download -r "${PROJECT_ROOT}/ansible/requirements.yml" -p "${COLLECTIONS_DIR}"
fi

# Download PowerShell modules
if command -v pwsh &> /dev/null; then
    echo "Downloading PowerShell modules..."
    pwsh -File "${PSMODULES_DIR}/download-modules.ps1"
else
    echo "Warning: PowerShell Core (pwsh) not found. Skipping PowerShell module downloads."
fi

echo "Dependencies caching completed!"