#!/bin/bash

# Get the absolute path to the offline_cache directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CACHE_DIR="$(dirname "${SCRIPT_DIR}")"

# Verify we're in the correct directory
if [[ ! -d "${CACHE_DIR}/scripts" ]]; then
    echo "Error: Could not locate the offline_cache directory"
    exit 1
fi

echo "Clearing cache directories..."

# Define directories to clear
DIRS_TO_CLEAR=(
    "${CACHE_DIR}/installers"
    "${CACHE_DIR}/ansible-collections"
    "${CACHE_DIR}/pip-packages"
    "${CACHE_DIR}/powershell-modules"
    "${CACHE_DIR}/exchange"
    "${CACHE_DIR}/sql-server"
    "${CACHE_DIR}/elk"
    "${CACHE_DIR}/wazuh"
)

# Clear each directory
for dir in "${DIRS_TO_CLEAR[@]}"; do
    if [[ -d "${dir}" ]]; then
        echo "Clearing ${dir}..."
        rm -rf "${dir:?}"/*
    else
        echo "Creating ${dir}..."
        mkdir -p "${dir}"
    fi
done

echo "Cache cleared successfully!"