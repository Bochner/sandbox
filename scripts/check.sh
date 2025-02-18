#!/usr/bin/env bash

# This source code come from the opensource project DetectionLab : https://github.com/clong/DetectionLab
# This script is meant to verify that your system is configured to build the lab successfully.

ERROR=$(tput setaf 1; echo -n "  [!]"; tput sgr0)
GOODTOGO=$(tput setaf 2; echo -n "  [✓]"; tput sgr0)
INFO=$(tput setaf 3; echo -n "  [-]"; tput sgr0)

PROVIDERS="virtualbox vmware azure proxmox vmware_esxi"
ANSIBLE_HOSTS="docker local"
print_usage() {
  echo "Usage: ./check.sh <provider> <ansible_host>"
  echo "provider must be one of the following:"
  for p in $PROVIDERS;  do
    echo " - $p";
  done
  echo "Ansible host must be one of the following:"
  for a in $ANSIBLE_HOSTS;  do
    echo " - $a";
  done
  exit 0
}

if [ $# -lt 2 ]; then
  print_usage
else
  PROVIDER=$1
  ANSIBLE_HOST=$2
fi

check_vagrant_path() {
  if ! which vagrant >/dev/null; then
    (echo >&2 "${ERROR} Vagrant was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing Vagrant : https://www.vagrantup.com/downloads.html")
    exit 1
  else
    (echo >&2 "${GOODTOGO} Vagrant was found in your PATH")

    # Ensure Vagrant >= 2.2.9
    # https://unix.stackexchange.com/a/285928
    VAGRANT_VERSION="$(vagrant --version | cut -d ' ' -f 2)"
    REQUIRED_VERSION="2.2.9"
    # If the version of Vagrant is not greater or equal to the required version
    if ! [ "$(printf '%s\n' "$REQUIRED_VERSION" "$VAGRANT_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        (echo >&2 "${ERROR} WARNING: It is highly recommended to use Vagrant $REQUIRED_VERSION or above before continuing")
    else 
        (echo >&2 "${GOODTOGO} Your version of Vagrant ($VAGRANT_VERSION) is supported")
    fi
  fi
}

check_packer_path() {
  if ! which packer >/dev/null; then
    (echo >&2 "${ERROR} packer was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing packer : https://developer.hashicorp.com/packer/docs/install")
    exit 1
  else
    (echo >&2 "${GOODTOGO} packer was found in your PATH")
  fi
}

check_terraform_path() {
  if ! which terraform >/dev/null; then
    (echo >&2 "${ERROR} terraform was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing terraform : https://developer.hashicorp.com/terraform/downloads")
    exit 1
  else
    (echo >&2 "${GOODTOGO} terraform was found in your PATH")
  fi
}

check_sshpass_path() {
  if ! which sshpass >/dev/null; then
    (echo >&2 "${ERROR} sshpass was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing sshpass")
    exit 1
  else
    (echo >&2 "${GOODTOGO} sshpass was found in your PATH")
  fi
}

# Returns 0 if not installed or 1 if installed
check_virtualbox_installed() {
  if ! which VBoxManage >/dev/null; then
    (echo >&2 "${ERROR} VBoxManage was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing virtualbox")
    exit 1
  else
    (echo >&2 "${GOODTOGO} virtualbox is installed")
  fi
}

check_aws_installed() {
  if ! which aws >/dev/null; then
    (echo >&2 "${ERROR} aws was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing aws (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} aws is installed")
  fi
}

check_azure_installed() {
  if ! which az >/dev/null; then
    (echo >&2 "${ERROR} az was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing az (https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} azure is installed")
  fi
}

check_rsync_path() {
  if ! which rsync >/dev/null; then
    (echo >&2 "${ERROR} rsync was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    exit 1
  else
    (echo >&2 "${GOODTOGO} rsync was found in your PATH")
  fi
}

# Returns 0 if not installed or 1 if installed
# Check for VMWare Workstation on Linux
check_vmware_workstation_installed() {
  if ! which vmrun >/dev/null; then
    (echo >&2 "${ERROR} vmrun was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing vmware")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vmware is installed")
  fi
}

check_docker_installed() {
  if ! which docker >/dev/null; then
    (echo >&2 "${ERROR} docker was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} docker is installed")
  fi
}

check_ansible_installed() {
  if ! which ansible >/dev/null; then
    (echo >&2 "${ERROR} ansible was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} ansible is installed")
  fi
}

check_python_env(){
  if ! which python3 >/dev/null; then
    (echo >&2 "${ERROR} python3 was not found in your PATH.")
  else
    (echo >&2 "${GOODTOGO} python3 is installed")
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    REQUIRED_VERSION="3.8"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
      (echo >&2 "${GOODTOGO} python3 ($PYTHON_VERSION) is supported")
      check_ansible_env
    else
      (echo >&2 "${ERROR} python3 ($PYTHON_VERSION) is not supported start checking other available python interpreter")
      check_python_venv
      exit 1
    fi
  fi
}

check_python_venv(){
    PYTHON_INSTALLED=$(ls -1 /usr/bin/python* | grep '.*[3]\(.[0-9]\+\)\?$')
    REQUIRED_VERSION="3.8"
    GOOD_PYTHON=""
    (echo >&2 "${GOODTOGO} Supported python3 interpreter :")
    for python_interpreter in $PYTHON_INSTALLED;  do
      PYTHON_VERSION="$($python_interpreter --version | cut -d ' ' -f 2)"
      # If the version of python is not greater or equal to the required version
      if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
          (echo >&2 "  ${GOODTOGO} $python_interpreter ($PYTHON_VERSION) is supported")
          GOOD_PYTHON=$(echo "$GOOD_PYTHON" "$python_interpreter")
      fi
    done

    INTERPRETER_FOUND=0
    if [ "$GOOD_PYTHON" != "" ]; then
      (echo >&2 "${GOODTOGO} Verify python3 available environment :")
      for python in $GOOD_PYTHON; do
        (echo >&2 "${GOODTOGO} Checking $python :")
        VENV_FOUND=0
        VIRTUALENV_FOUND=0
        PIP_FOUND=0
        if [ "$($python -m venv -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python venv module is installed")
          VENV_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python venv module not installed")
        fi

        if [ "$($python -m virtualenv -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python virtualenv module is installed")
          VIRTUALENV_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python virtualenv module not installed")
        fi

        if [ "$($python -m pip -h 2>/dev/null | grep -i 'usage:')" ]; then
          (echo >&2 "  ${GOODTOGO} $python pip module is installed")
          PIP_FOUND=1
        else
          (echo >&2 "  ${ERROR} $python pip module not installed")
        fi

        if [[ $PIP_FOUND -eq 1 ]] && [[ $VENV_FOUND -eq 1 || $VIRTUALENV_FOUND -eq 1 ]]; then
          if [ "$VIRTUALENV_FOUND" -eq 1 ]; then
            (echo >&2 "  ${GOODTOGO} $python environment is available consider creating a venv : \"$python -m virtualenv .venv\", activate it with source .venv/bin/activate and relaunch the prepare script")
          else
            (echo >&2 "  ${GOODTOGO} $python environment is available consider creating a venv : \"$python -m venv .venv\", activate it with source .venv/bin/activate and relaunch the prepare script")
          fi
          INTERPRETER_FOUND=1
        fi
      done
    fi

    if [ "$INTERPRETER_FOUND" -eq 1 ]; then
      (echo >&2 "  ${ERROR} no available interpreter found, please install pip and venv")
    fi
}

check_ansible_env(){
  (echo >&2 "${GOODTOGO} Checking if python3 env is ansible ready :")
  ANSIBLE_CORE_CHECK=$(python3 -m pip --disable-pip-version-check list|grep -c ansible-core)
  if [ "$ANSIBLE_CORE_CHECK" -eq 1 ]; then
    ANSIBLE_VERSION=$(python3 -m pip --disable-pip-version-check list|grep ansible-core|cut -d ' ' -f 2-|sed -e 's/ //g' )
    REQUIRED_VERSION="2.12.6"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$ANSIBLE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
      (echo >&2 "  ${GOODTOGO} ansible-core $ANSIBLE_VERSION  is supported")
    else
      (echo >&2 "  ${ERROR} $ANSIBLE_VERSION  is not supported consider doing :")
      echo "        python3 -m pip install ansible-core==2.12.6"
    fi
  else
    (echo >&2 "  ${ERROR} ansible-core is not installed consider doing :")
    echo "        python3 -m pip install ansible-core==2.12.6"
  fi

  PYWINRM_CHECK=$(python3 -m pip --disable-pip-version-check list |grep -c pywinrm )
  if [ "$PYWINRM_CHECK" -eq 1 ]; then
    (echo >&2 "  ${GOODTOGO} pywinrm is installed")
  else
    (echo >&2 "  ${ERROR} pywinrm  is not install consider doing :")
    echo "        python3 -m pip install pywinrm"
    exit 1
  fi

  if ! which ansible >/dev/null; then
    (echo >&2 "${ERROR} ansible was not found in your PATH abort")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible is installed")
  fi

  if ! which ansible-galaxy >/dev/null; then
    (echo >&2 "${ERROR} ansible-galaxy was not found in your PATH abort")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible-galaxy is installed")
  fi

  GALAXY_COLLECTION=$(ansible-galaxy collection list)
  ANSIBLE_COLLECTION_EXPECTED="community.windows community.general ansible.windows"
  GALAXY_OK=1
  for collection in $ANSIBLE_COLLECTION_EXPECTED; do
    if [ $(echo $GALAXY_COLLECTION|grep -c $collection) -eq 1 ]; then
      (echo >&2 "  ${GOODTOGO} ansible-galaxy collection $collection installed")
    else
      (echo >&2 "  ${ERROR} ansible-galaxy collection $collection not installed")
      GALAXY_OK=0
    fi
  done
  if [ $GALAXY_OK -eq 0 ]; then
    (echo >&2 "${ERROR} ansible-galaxy requirements missing consider doing : ansible-galaxy install -r ansible/requirements.yml")
    exit 1
  else
    (echo >&2 "${GOODTOGO} ansible-galaxy requirements ok")
  fi
}

# Returns 0 if not installed or 1 if installed
check_vmware_desktop_vagrant_plugin_installed() {
  LEGACY_PLUGIN_CHECK="$(vagrant plugin list | grep -c 'vagrant-vmware-fusion')"
  if [ "$LEGACY_PLUGIN_CHECK" -gt 0 ]; then
    (echo >&2 "${ERROR} The VMware Fusion Vagrant plugin is deprecated and is no longer supported.")
    (echo >&2 "${INFO} Please upgrade to the VMware Desktop plugin: https://www.vagrantup.com/docs/vmware/installation.html")
    (echo >&2 "${INFO} Please also uninstall the vagrant-vmware-fusion plugin and install the vmware-vagrant-desktop plugin")
    (echo >&2 "${INFO} HINT: \`vagrant plugin uninstall vagrant-vmware-fusion && vagrant plugin install vagrant-vmware-desktop\`")
    (echo >&2 "${INFO} NOTE: The VMware plugin does not work with trial versions of VMware Fusion")
    exit 1
  fi

  VMWARE_DESKTOP_PLUGIN_PRESENT="$(vagrant plugin list | grep -c 'vagrant-vmware-desktop')"
  if [ "$VMWARE_DESKTOP_PLUGIN_PRESENT" -eq 0 ]; then
    (echo >&2 "VMWare Fusion or Workstation is installed, but the vagrant-vmware-desktop plugin is not.")
    (echo >&2 "Visit https://www.hashicorp.com/blog/introducing-the-vagrant-vmware-desktop-plugin for more information on how to purchase and install it")
    (echo >&2 "VMWare Fusion or Workstation will not be listed as a provider until the vagrant-vmware-desktop plugin has been installed.")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vagrant-vmware-desktop plugin installed")
  fi
}

check_vagrant_vmware_utility_installed() {
  # Ensure the helper utility is installed: https://www.vagrantup.com/docs/providers/vmware/vagrant-vmware-utility
  if ! pgrep -f vagrant-vmware-utility > /dev/null; then
    (echo >&2 "${ERROR} vagrant-vmware-utility is not installed (https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility)")
    exit 1
  else
    (echo >&2 "${GOODTOGO} vagrant-vmware-utility installed")
  fi
}

# Check to see if any Vagrant instances exist already
check_vagrant_instances_exist() {
  cd "$VAGRANT_DIR"|| exit 1
  # Vagrant status has the potential to return a non-zero error code, so we work around it with "|| true"
  VAGRANT_STATUS_OUTPUT=$(vagrant status)
  VAGRANT_BUILT=$(echo "$VAGRANT_STATUS_OUTPUT" | grep -c 'not created') || true
  if [ "$VAGRANT_BUILT" -ne 4 ]; then
    (echo >&2 "${INFO} You appear to have already created at least one Vagrant instance:")
    # shellcheck disable=SC2164
    cd "$VAGRANT_DIR" && echo "$VAGRANT_STATUS_OUTPUT" | grep -v 'not created' | grep -E 'logger|dc|wef|win10' 
    (echo >&2 "${INFO} If you want to start with a fresh install, you should run \`vagrant destroy -f\` to remove existing instances.")
  else 
    (echo >&2 "${GOODTOGO} No Vagrant instances have been created yet")
  fi
}

check_vagrant_reload_plugin() {
  # Ensure the vagrant-reload plugin is installed
  VAGRANT_RELOAD_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-reload')
  if [ "$VAGRANT_RELOAD_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-reload plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-reload"; then
      (echo >&2 "Unable to install the vagrant-reload plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-reload plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-reload plugin is currently installed")
  fi
}

check_vagrant_esxi_plugin() {
  # Ensure the vagrant-vmware-esxi plugin is installed
  VAGRANT_ESXI_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-vmware-esxi')
  if [ "$VAGRANT_ESXI_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-vmware-esxi plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-vmware-esxi"; then
      (echo >&2 "Unable to install the vagrant-vmware-esxi plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-vmware-esxi plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-vmware-esxi plugin is currently installed")
  fi
}

check_vagrant_env_plugin() {
  # Ensure the vagrant-env plugin is installed
  VAGRANT_ENV_PLUGIN_INSTALLED=$(vagrant plugin list | grep -c 'vagrant-env')
  if [ "$VAGRANT_ENV_PLUGIN_INSTALLED" != "1" ]; then
    (echo >&2 "${ERROR} The vagrant-env plugin is required and was not found. This script will attempt to install it now.")
    if ! $(which vagrant) plugin install "vagrant-env"; then
      (echo >&2 "Unable to install the vagrant-env plugin. Please try to do so manually and re-run this script.")
      exit 1
    else 
      (echo >&2 "${GOODTOGO} The vagrant-env plugin was successfully installed!")
    fi
  else
    (echo >&2 "${GOODTOGO} The vagrant-env plugin is currently installed")
  fi
}

check_ovftool_installed() {
  if ! which ovftool >/dev/null; then
    (echo >&2 "${ERROR} ovftool was not found in your PATH.")
    (echo >&2 "${ERROR} Please correct this before continuing. Exiting.")
    (echo >&2 "${ERROR} Correct this by installing appropriate ovftool version for your environment : https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest")
    exit 1
  else
    OVFTOOL_VERSION=$(ovftool -v | cut -d ' ' -f 3)
    (echo >&2 "${GOODTOGO} ovftool (${OVFTOOL_VERSION}) is installed, make sure that version matches your ESXi environment")
  fi
}

# Check available disk space. Recommend 120GB free, warn if less.
check_disk_free_space() {
  FREE_DISK_SPACE=$(df -m "$HOME" | tr -s ' ' | grep '/' | cut -d ' ' -f 4)
  if [ "$FREE_DISK_SPACE" -lt 120000 ]; then
    (echo >&2 "${INFO} Warning: You appear to have less than 120GB of HDD space free on your primary partition. If you are using a separate parition, you may ignore this warning.\n")
  else
    (echo >&2 "${GOODTOGO} You have more than 120GB of free space on your primary partition")
  fi
}

check_ram_space() {
  RAM_SPACE=$(free|tr -s ' '|grep Mem|cut -d ' ' -f 2)
  if [ "$RAM_SPACE" -lt 24000000 ]; then
    (echo >&2 "${INFO} Warning: You appear to have less than 24GB of RAM on your disk, you should consider running only a part of the lab.\n")
  else
    (echo >&2 "${GOODTOGO} You have more than 24GB of ram")
  fi
}

check_offline_cache() {
  echo "Checking offline cache..."
  CACHE_DIR="offline_cache"
  
  # Define expected directories
  DIRS=(
    "${CACHE_DIR}/installers"
    "${CACHE_DIR}/ansible-collections"
    "${CACHE_DIR}/pip-packages"
    "${CACHE_DIR}/powershell-modules"
    "${CACHE_DIR}/exchange/prerequisites"
    "${CACHE_DIR}/sql-server"
    "${CACHE_DIR}/elk/server"
    "${CACHE_DIR}/elk/windows-agent"
    "${CACHE_DIR}/elk/linux-agent"
    "${CACHE_DIR}/wazuh/server"
    "${CACHE_DIR}/wazuh/windows-agent"
    "${CACHE_DIR}/wazuh/linux-agent"
  )

  # Check directories exist
  for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
      (echo >&2 "  ${GOODTOGO} Directory $dir exists")
    else
      (echo >&2 "  ${ERROR} Directory $dir missing")
      return 1
    fi
  done

  # Check essential files
  REQUIRED_FILES=(
    "${CACHE_DIR}/installers/LAPS.x64.msi"
    "${CACHE_DIR}/installers/vc_redist.x64.exe"
    "${CACHE_DIR}/exchange/prerequisites/Exchange2019-x64-cu13.iso"
    "${CACHE_DIR}/exchange/prerequisites/UcmaRuntimeSetup.exe"
    "${CACHE_DIR}/exchange/prerequisites/rewrite_amd64_en-US.msi"
    "${CACHE_DIR}/sql-server/SQLServer2019.iso"
    "${CACHE_DIR}/sql-server/SQLServer2022.iso"
    "${CACHE_DIR}/elk/winlogbeat-8.11.1-windows-x86_64.zip"
    "${CACHE_DIR}/elk/server/elasticsearch-8.11.1-linux-x86_64.tar.gz"
    "${CACHE_DIR}/elk/server/kibana-8.11.1-linux-x86_64.tar.gz"
    "${CACHE_DIR}/elk/server/logstash-8.11.1-linux-x86_64.tar.gz"
    "${CACHE_DIR}/elk/windows-agent/winlogbeat-8.11.1-windows-x86_64.zip"
    "${CACHE_DIR}/elk/windows-agent/filebeat-8.11.1-windows-x86_64.zip"
    "${CACHE_DIR}/wazuh/server/wazuh-manager_4.7.2-1_amd64.deb"
    "${CACHE_DIR}/wazuh/server/wazuh-indexer_4.7.2-1_amd64.deb"
    "${CACHE_DIR}/wazuh/server/wazuh-dashboard_4.7.2-1_amd64.deb"
    "${CACHE_DIR}/wazuh/windows-agent/wazuh-agent-4.7.2-1.msi"
    "${CACHE_DIR}/wazuh/linux-agent/wazuh-agent_4.7.2-1_amd64.deb"
  )

  for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
      (echo >&2 "  ${GOODTOGO} File $file exists")
    else
      (echo >&2 "  ${ERROR} Required file $file missing")
      return 1
    fi
  done

  # Check PowerShell modules
  PS_MODULES=(
    "${CACHE_DIR}/powershell-modules/modules/PowerShellGet"
    "${CACHE_DIR}/powershell-modules/modules/PackageManagement"
    "${CACHE_DIR}/powershell-modules/modules/xActiveDirectory"
    "${CACHE_DIR}/powershell-modules/modules/SecurityPolicyDsc"
    "${CACHE_DIR}/powershell-modules/modules/NetworkingDsc"
    "${CACHE_DIR}/powershell-modules/modules/ComputerManagementDsc"
  )

  for module in "${PS_MODULES[@]}"; do
    if [ -d "$module" ]; then
      (echo >&2 "  ${GOODTOGO} PowerShell module $module exists")
    else
      (echo >&2 "  ${ERROR} PowerShell module $module missing")
      return 1
    fi
  done

  # Check pip packages exist
  if [ -z "$(ls -A ${CACHE_DIR}/pip-packages/*.whl 2>/dev/null)" ]; then
    (echo >&2 "  ${ERROR} No pip packages found in ${CACHE_DIR}/pip-packages")
    return 1
  else
    (echo >&2 "  ${GOODTOGO} Pip packages found")
  fi

  # Check ansible collections exist
  if [ -z "$(ls -A ${CACHE_DIR}/ansible-collections/*.tar.gz 2>/dev/null)" ]; then
    (echo >&2 "  ${ERROR} No ansible collections found in ${CACHE_DIR}/ansible-collections")
    return 1
  else
    (echo >&2 "  ${GOODTOGO} Ansible collections found")
  fi

  return 0
}

main() {
  # Get location of prepare.sh
  # https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
  VAGRANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  case $PROVIDER in
    "virtualbox")
      (echo >&2 "[+] Enumerating virtualbox")
      check_virtualbox_installed
      check_vagrant_path
      check_vagrant_reload_plugin
      check_disk_free_space
      check_ram_space
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "vmware")
      (echo >&2 "[+] Enumerating vmware")
      check_vmware_workstation_installed
      check_vagrant_path
      check_vagrant_reload_plugin
      check_vagrant_vmware_utility_installed
      check_vmware_desktop_vagrant_plugin_installed
      check_disk_free_space
      check_ram_space
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "vmware_esxi")
      (echo >&2 "[+] Enumerating vmware_esxi")
      check_vagrant_path
      check_vagrant_reload_plugin
      check_vagrant_esxi_plugin
      check_vagrant_env_plugin
      check_ovftool_installed
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "proxmox")
      (echo >&2 "[+] Enumerating proxmox")
      check_packer_path
      check_terraform_path
      case $ANSIBLE_HOST in
        "docker")
          check_docker_installed
          ;;
        "local")
          check_python_env
          ;;
        *)
          ;;
      esac
      ;;
    "azure")
      (echo >&2 "[+] Enumerating azure")
      check_azure_installed
      check_terraform_path
      check_rsync_path
      ;;
    "aws")
      (echo >&2 "[+] Enumerating aws")
      check_aws_installed
      check_terraform_path
      check_rsync_path
      ;;
    *)
      print_usage
      ;;
  esac
}

main 
exit 0

#!/bin/bash

CACHE_DIR="cache"
INSTALLERS_DIR="${CACHE_DIR}/installers"
COLLECTIONS_DIR="${CACHE_DIR}/ansible-collections"
PIP_DIR="${CACHE_DIR}/pip-packages"
PSMODULES_DIR="${CACHE_DIR}/powershell-modules"

check_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        return 1
    else
        echo "✓ Found: $file"
        return 0
    fi
}

echo "Checking cached installers..."
REQUIRED_INSTALLERS=(
    "${INSTALLERS_DIR}/LAPS.x64.msi"
    "${INSTALLERS_DIR}/vc_redist.x64.exe"
    "${INSTALLERS_DIR}/odbc_driver.msi"
    "${INSTALLERS_DIR}/MCM_Configmgr_2303.exe"
    "${INSTALLERS_DIR}/UcmaRuntimeSetup.exe"
    "${INSTALLERS_DIR}/rewrite_amd64_en-US.msi"
)

MISSING_FILES=0
for file in "${REQUIRED_INSTALLERS[@]}"; do
    check_file "$file" || ((MISSING_FILES++))
done

echo -e "\nChecking pip packages..."
if [ ! -d "${PIP_DIR}" ] || [ -z "$(ls -A ${PIP_DIR})" ]; then
    echo "❌ Missing pip packages in ${PIP_DIR}"
    ((MISSING_FILES++))
else
    echo "✓ Pip packages found"
fi

echo -e "\nChecking ansible collections..."
if [ ! -d "${COLLECTIONS_DIR}" ] || [ -z "$(ls -A ${COLLECTIONS_DIR})" ]; then
    echo "❌ Missing ansible collections in ${COLLECTIONS_DIR}"
    ((MISSING_FILES++))
else
    echo "✓ Ansible collections found"
fi

echo -e "\nChecking PowerShell modules..."
REQUIRED_PS_MODULES=(
    "ActiveDirectory"
    "PowerShellGet"
    "PackageManagement"
    "ADCSTemplate"
    "xActiveDirectory"
    "xAdcsDeployment"
)

for module in "${REQUIRED_PS_MODULES[@]}"; do
    if [ ! -d "${PSMODULES_DIR}/modules/${module}" ]; then
        echo "❌ Missing PowerShell module: ${module}"
        ((MISSING_FILES++))
    else
        echo "✓ Found PowerShell module: ${module}"
    fi
done

if [ ! -d "${PSMODULES_DIR}/nuget/providers" ]; then
    echo "❌ Missing NuGet provider cache"
    ((MISSING_FILES++))
else
    echo "✓ NuGet provider cache found"
fi

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "\n✅ All required files are cached and ready for offline use"
    exit 0
else
    echo -e "\n❌ Missing $MISSING_FILES required components. Please run cache_dependencies.sh first"
    exit 1
fi
